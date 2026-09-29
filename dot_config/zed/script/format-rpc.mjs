const MAX_BODY_BYTES = 16 * 1024 * 1024;
const MAX_HEADER_BYTES = 64 * 1024;
const REQUEST_TIMEOUT_MS = 15000;

export const createRpc = ({ input, output, onRequest, onNotification, onClose }) => {
  let buffer = Buffer.alloc(0);
  let nextId = 1;
  let closed = false;
  const pending = new Map();

  const close = (reason = new Error("RPC connection closed")) => {
    if (closed) return;
    closed = true;
    for (const { reject, timer } of pending.values()) {
      clearTimeout(timer);
      reject(reason);
    }
    pending.clear();
    onClose?.(reason);
  };

  const send = (message) => {
    if (closed) throw new Error("RPC connection closed");
    const body = Buffer.from(JSON.stringify({ jsonrpc: "2.0", ...message }));
    if (body.length > MAX_BODY_BYTES) throw new Error("RPC message exceeds 16 MiB");
    output.write(`Content-Length: ${body.length}\r\n\r\n`);
    output.write(body);
  };

  const request = (method, params) => {
    const id = nextId++;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        close(new Error(`RPC request timed out: ${method}`));
      }, REQUEST_TIMEOUT_MS);
      pending.set(id, { resolve, reject, timer });
      try {
        send({ id, method, params });
      } catch (error) {
        clearTimeout(timer);
        pending.delete(id);
        reject(error);
      }
    });
  };

  const receive = (message) => {
    if (message.method) {
      if (message.id === undefined) {
        Promise.resolve(onNotification?.(message.method, message.params)).catch((error) => {
          process.stderr.write(`${error.message}\n`);
        });
        return;
      }
      Promise.resolve()
        .then(() => onRequest?.(message.method, message.params))
        .then((result) => send({ id: message.id, result: result ?? null }))
        .catch((error) => {
          try {
            send({ id: message.id, error: { code: -32603, message: error.message } });
          } catch {
            close(error);
          }
        });
      return;
    }

    const entry = pending.get(message.id);
    if (!entry) return;
    clearTimeout(entry.timer);
    pending.delete(message.id);
    if (message.error) {
      entry.reject(new Error(message.error.message ?? "RPC request failed"));
    } else {
      entry.resolve(message.result);
    }
  };

  input.on("data", (chunk) => {
    if (closed) return;
    buffer = Buffer.concat([buffer, chunk]);
    try {
      while (buffer.length > 0) {
        const headerEnd = buffer.indexOf("\r\n\r\n");
        if (headerEnd < 0) {
          if (buffer.length > MAX_HEADER_BYTES) throw new Error("RPC header exceeds 64 KiB");
          break;
        }
        if (headerEnd > MAX_HEADER_BYTES) throw new Error("RPC header exceeds 64 KiB");
        const header = buffer.subarray(0, headerEnd).toString();
        const match = /^Content-Length:\s*(\d+)\s*$/im.exec(header);
        const length = Number(match?.[1]);
        if (!Number.isSafeInteger(length) || length < 0 || length > MAX_BODY_BYTES) {
          throw new Error("Invalid RPC Content-Length");
        }
        const bodyStart = headerEnd + 4;
        if (buffer.length < bodyStart + length) break;
        const body = buffer.subarray(bodyStart, bodyStart + length);
        buffer = buffer.subarray(bodyStart + length);
        receive(JSON.parse(body.toString()));
      }
    } catch (error) {
      process.stderr.write(`${error.message}\n`);
      close(error);
      input.destroy();
    }
  });
  input.on("end", () => close());
  input.on("error", close);
  output.on("error", close);

  return { request, notify: (method, params) => send({ method, params }), close };
};
