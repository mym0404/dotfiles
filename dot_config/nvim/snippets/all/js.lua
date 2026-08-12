local util = require("utils/utils")

local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local events = require("luasnip.util.events")
local ai = require("luasnip.nodes.absolute_indexer")
local extras = require("luasnip.extras")
local l = extras.lambda
local rep = extras.rep
local p = extras.partial
local m = extras.match
local n = extras.nonempty
local dl = extras.dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local conds = require("luasnip.extras.expand_conditions")
local postfix = require("luasnip.extras.postfix").postfix
local types = require("luasnip.util.types")
local parse = require("luasnip.util.parser").parse_snippet
local ms = ls.multi_snippet
local k = require("luasnip.nodes.key_indexer").new_key

local function capitalize(args)
  local word = args[1][1]
  return (word:gsub("^%l", string.upper))
end

return {
  s(
    "zod schema",
    fmt(
      [[
export const {}Schema = z.object({{
  {}
}});
export type {} = z.infer<typeof {}Schema>;
    ]],
      {
        i(1, "name"),
        i(0),
        f(capitalize, { 1 }),
        rep(1),
      }
    )
  ),
  s(
    "Function Component",
    fmt(
      [[
type {}Props = {{
  {}
}};
const {} = ({{ {} }}: {}Props) => {{
  return null;
}};

export {{ {} }}
export type {{ {}Props }}
  ]],
      {
        i(1, "Component"),
        i(2),
        rep(1),
        i(0),
        rep(1),
        rep(1),
        rep(1),
      }
    )
  ),
  s(
    "ZustandProvider",
    fmt(
      [[
export type {}State = {{}}
export type {}Action = {{}}
const initialState: {}State = {{}}

export const {{ Provider: {}Provider, useStoreProvider: use{}, useStoreProviderShallow: use{}Shallow }} =
  createZustandStoreProvider<{}State & {}Action>({{
    name: '{}',
    creator: immer((set, get) => ({{
      ...initialState
    }})
  }})
{}
]],
      {
        i(1, "Store"),
        rep(1),
        rep(1),
        rep(1),
        rep(1),
        rep(1),
        rep(1),
        rep(1),
        rep(1),
        i(0),
      }
    )
  ),
  s(
    "ReBottomSheet",
    fmt(
      [[
const [{} , {{show, hide}}] = useDialog();

<{}Dialog dialog={{dialog}} />

const {}Dialog = (props: DialogProps) => {{
  const [dialog, {{hide}}] = useDialogProps(props);

  return (
    <Dialog dialog={{dialog}} bottomSheet>
      <BottomSheetContainer title={{'Title'}} close={{hide}}>
        {}
      </BottomSheetContainer>
    </Dialog>
  );
}};
]],
      {
        i(1, "Example"),
        rep(1),
        rep(1),
        i(0),
      }
    )
  ),
  s(
    "Provider",
    fmt(
      [[
export const [use{}Context, {}Provider, {}Consumer] = createCtx(() => {{
    {}
    return {{}};
}}, '{}');
]],
      {
        i(1, "Example"),
        rep(1),
        rep(1),
        i(0),
        rep(1),
      }
    )
  ),
  s("Expo_Page", {
    t({
      "export default function Page() {",
      "   return <Box className={'flex-1'} />;",
      "}",
    }),
  }),
  s("Next_Page", {
    t({
      "export const metadata: Metadata = {",
      "  title: '',",
      "};",
      "",
      "type Props = {",
      "  params: Promise<{ id: string }>;",
      "  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;",
      "};",
      "",
      "export async function generateMetadata(",
      "  { params, searchParams }: Props,",
      "  parent: ResolvingMetadata,",
      "): Promise<Metadata> {",
      "  // read route params",
      "  const id = (await params).id;",
      "",
      "  return {",
      "    title: '',",
      "  };",
      "}",
      "",
      "export function generateStaticParams() {",
      "  return [];",
      "}",
      "",
      "export default function Page() {",
      "  return null;",
      "}",
    }),
  }),
  s("LocalStorageMMKV", {
    t(util.to_str_list([[
import { useCallback, useRef, useState } from 'react';
import { MMKV } from 'react-native-mmkv';
import type { StateStorage } from 'zustand/middleware/persist';

const mmkv = new MMKV();

type Options<T> = {
  putAndReturnIfAbsent?: T;
  returnIfAbsent?: T;
};

type DefaultGetFunction<T> = (key: string, options: Options<T>) => T;

class LocalStorage {
  set = <T extends number | string | boolean>(key: string, value: T) => {
    mmkv.set(key, value);
  };

  private createWithDefaultFunction = <T extends number | string | boolean>({
    isValidValueChecker,
    getter,
  }: {
    isValidValueChecker: (data?: T) => boolean;
    getter: (key: string) => T | undefined;
  }): DefaultGetFunction<T> => {
    return (key, { putAndReturnIfAbsent, returnIfAbsent }) => {
      if (!isValidValueChecker(putAndReturnIfAbsent) && !isValidValueChecker(returnIfAbsent)) {
        throw new Error('putAndReturnIfAbsent or returnIfAbsent should be not nullable');
      }

      let ret = getter(key);
      if (isValidValueChecker(ret)) {
        return ret!;
      } else {
        if (isValidValueChecker(putAndReturnIfAbsent)) {
          this.set(key, putAndReturnIfAbsent as any);
          return putAndReturnIfAbsent!;
        } else {
          return returnIfAbsent!;
        }
      }
    };
  };

  getString = (key: string): string | undefined => mmkv.getString(key);
  getStringWithDefault = this.createWithDefaultFunction<string>({
    isValidValueChecker: (d) => typeof d === 'string',
    getter: this.getString,
  });
  getNumber = (key: string): number | undefined => mmkv.getNumber(key);
  getNumberWithDefault = this.createWithDefaultFunction<number>({
    isValidValueChecker: (d) => typeof d === 'number',
    getter: this.getNumber,
  });
  getBoolean = (key: string): boolean | undefined => mmkv.getBoolean(key);
  getBooleanWithDefault = this.createWithDefaultFunction<boolean>({
    isValidValueChecker: (d) => typeof d === 'boolean',
    getter: this.getBoolean,
  });

  setArray = <T>(key: string, values: T[]) => {
    this.set(key, JSON.stringify(values));
  };
  getArray = <T>(key: string, defaultValue: T[] = []): T[] => {
    const raw: string | undefined = this.getString(key)?.trim();
    if (raw && raw[0] === '[' && raw[raw.length - 1] === ']') {
      return JSON.parse(raw) as T[];
    } else {
      this.setArray(key, defaultValue);
      return defaultValue;
    }
  };

  setObject = <T extends object>(key: string, value: T) => {
    this.set(key, JSON.stringify(value));
  };
  getObject = <T extends object>(key: string, defaultValue?: T): T | undefined => {
    const raw: string | undefined = this.getString(key)?.trim();
    if (raw && raw[0] === '{' && raw[raw.length - 1] === '}') {
      return JSON.parse(raw) as T;
    } else {
      return defaultValue;
    }
  };

  remove = (key: string) => mmkv.delete(key);
}

function createHook<
  T extends (boolean | number | string | Uint8Array) | undefined,
  TSet extends T | undefined,
  TSetAction extends TSet | ((current: T) => TSet),
>(getter: (key: string, options: Options<T>) => T) {
  return (key: string, options: Options<T>): [value: T, setValue: (value: TSetAction) => void] => {
    const [value, setValue] = useState<T>(() => getter(key, options));
    const valueRef = useRef<T>(value);
    valueRef.current = value;

    // update value by user set
    const set = useCallback(
      (v: TSetAction) => {
        const newValue: TSet = (typeof v === 'function' ? v(valueRef.current) : v) as TSet;
        switch (typeof newValue) {
          case 'number':
          case 'string':
          case 'boolean':
            mmkv.set(key, newValue);
            break;
          case 'undefined':
            mmkv.delete(key);
            break;
          default:
            throw new Error(`MMKV: Type ${typeof newValue} is not supported!`);
        }
        setValue(getter(key, options));
      },
      [key, options],
    );

    // update value if it changes somewhere else (second hook, same key)
    // useEffect(() => {
    //   const listener = mmkv.addOnValueChangedListener((changedKey) => {
    //     if (changedKey === key) {
    //       setValue(getter(key));
    //     }
    //   });
    //   return () => listener.remove();
    // }, [key]);

    return [value, set];
  };
}
const instance = new LocalStorage();

export const useStorageString = createHook((key, options: Options<string>) =>
  instance.getStringWithDefault(key, options),
);
export const useStorageNumber = createHook((key, options: Options<number>) =>
  instance.getNumberWithDefault(key, options),
);
export const useStorageBoolean = createHook((key, options: Options<boolean>) =>
  instance.getBooleanWithDefault(key, options),
);
export const useStorageArray = <T>(key: string, defaultValue: T[] = []) => {
  const [value, setValue] = useState<T[]>(instance.getArray(key, defaultValue));
  const set = useCallback(
    (v: T[]) => {
      instance.setArray(key, v);
      setValue(v);
    },
    [key],
  );
  return [value, set] as const;
};
export const useStorageObject = <T extends object>(key: string, defaultValue?: T) => {
  const [value, setValue] = useState<T | undefined>(instance.getObject(key, defaultValue));
  const set = useCallback(
    (v: T) => {
      instance.setObject(key, v);
      setValue(v);
    },
    [key],
  );
  return [value, set] as const;
};

export const zustandPersistStorage: StateStorage = {
  setItem: (name: string, value: any) => {
    return instance.set(name, value);
  },
  getItem: (name: string) => {
    const value = instance.getString(name);
    return value ?? null;
  },
  removeItem: (name: string) => {
    return instance.remove(name);
  },
};

export default instance;
        ]])),
  }),
  s("createCtx", {
    t(util.to_str_list([[
import React, { ReactNode, createElement, ReactElement } from 'react';

export type ChildrenTransformer = (children?: ReactNode) => ReactNode | undefined;

function createCtx<T, P extends object>(
  delegate: (props: P, transformChildren: (transformer: ChildrenTransformer) => void) => T,
) {
  const context = React.createContext<T | undefined>(undefined);

  const Provider = ({ children: _children, ...props }: { children?: ReactNode } & P): ReactElement => {
    let children = _children;

    const value = delegate(props as P, (transformer) => {
      children = transformer(children);
    });

    return createElement(context.Provider, { value }, children);
  };

  return [
    () => {
      const c = React.useContext(context);
      if (!c) {
        throw new Error('useContext를 특정 Provider 내부에서 사용하지 않았습니다.');
      }
      return c;
    },
    Provider as P extends object ? typeof Provider : React.ComponentType<{ children?: ReactNode }>,
    context.Consumer as React.Consumer<T>,
  ] as const;
}

export default createCtx;

  ]])),
  }),
  s("zx-util", {
    t(util.to_str_list([[
#!/usr/bin/env zx
/* eslint-disable max-len */
// #region ZX Util
import fs from 'fs-extra'

const join = path.join;
const resolve = path.resolve;
const filename = path.basename(__filename);
const cwd = () => process.cwd();
const exit = process.exit;
const _printTag = '' || filename;

function exist(path) {
  return fs.existsSync(path);
}

function isDir(path) {
  return exist(path) && fs.lstatSync(path).isDirectory();
}

function isFile(path) {
  return exist(path) && fs.lstatSync(path).isFile();
}

async function iterateDir(path, fn) {
  if (!isDir(path)) {
    return;
  }

  for (const file of fs.readdirSync(path)) {
    await fn(file);
  }
}

function read(path) {
  return fs.readFileSync(path, { encoding: 'utf8' });
}

// you should require when possible(optimized in js)
function readJsonSlow(path) {
  return fs.readJSONSync(path);
}

function write(p, content) {
  const dir = path.dirname(p);
  if (!exist(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  return fs.writeFileSync(p, content);
}

function writeJson(path, json) {
  return write(path, JSON.stringify(json, null, 2));
}

function remove(path) {
  if (!exist(path)) {
    return;
  }

  if (fs.lstatSync(path).isDirectory()) {
    return fs.rmSync(path, { force: true, recursive: true });
  } else {
    return fs.rmSync(path, { force: true });
  }
}

function addLine(str, added, backward = false) {
  if (backward) {
    return added + '\n' + str;
  } else {
    return str + '\n' + added;
  }
}

function addLineToFile(path, added, backward = false) {
  return write(path, addLine(read(path), added, backward));
}

function print(...args) {
  echo(chalk.blue(`[${_printTag}]`, ...args));
}

function printSuccess(...args) {
  echo(chalk.bold.bgBlue(`[${_printTag}]`, ...args));
}

function printError(...args) {
  echo(chalk.bold.bgRed(`[${_printTag}]`, ...args));
}
function asrt(condition, ...args) {
if(!condition) {
  echo(chalk.bold.bgRed(`[${_printTag}]`, ...args));
  exit(1);
}
}

const tKey = {};

function measureBegin(name = '⏳') {
  print(`=======Start [${name}=======`);
  tKey[name] = Date.now();
}

function measureEnd(name = '⏳') {
  print(
    `=======End [${name}]==[${(Date.now() - tKey[name]).toLocaleString().split('.')[0]}ms]=======`,
  );
}

async function input(message) {
  if (message) {
    return question(message + ': ');
  } else {
    return stdin();
  }
}

async function fixLint(path) {
  await $`yarn prettier ${path} --write --log-level silent`;
  await $`yarn eslint ${path} --fix --quiet --max-warnings 100`;
}

const HEADING = `// @ts-nocheck
/* eslint-disable */
/**
 * Generated file. Don't modify manually.
 */
 `;

// #endregion

async function main(){

};
main();
  ]])),
  }),
  s(
    "createZustandPersistStore",
    fmt(
      [[
import {{ create }} from 'zustand';
import {{ persist, createJSONStorage }} from 'zustand/middleware';
import {{ immer }} from 'zustand/middleware/immer';

export type {}State = {{ _hasHydrated: boolean; _markHydrate: () => void; reset: () => void }};

const initialState: OmitFunctions<{}State> = {{ _hasHydrated: false }};

export const use{} = create<{}State>()(
  persist(
    immer((set, get) => {{
      return {{
        ...initialState,
        reset: () => set((s) => {{ return {{ ...initialState, _hasHydrated: s._hasHydrated }} }}, true),
        _markHydrate: () => set({{ _hasHydrated: true }}),
      }}
    }}),
    {{
      version: 0,
      name: '{}-storage',
      storage: createJSONStorage(() => zustandPersistStorage),
      onRehydrateStorage: (s) => () => s._markHydrate(),
    }}
  )
);

export const use{}Store = () => use{}(useShallow((s) => s));
]],
      {
        i(1, "Name"),
        rep(1),
        rep(1),
        rep(1),
        rep(1),
        rep(1),
        rep(1),
      }
    )
  ),
  s(
    "createZustandStore",
    fmt(
      [[
import {{ create }} from 'zustand';
import {{ immer }} from 'zustand/middleware/immer';

export type {}State = {{ reset: () => void }};

const initialState: OmitFunctions<{}State> = {{}};

export const use{} = create<{}State>()(
  immer((set, get) => {{
    return {{
      ...initialState,
      reset: () => set(initialState),
    }}
  }})
);

export const use{}Store = () => use{}(useShallow((s) => s));
]],
      {
        i(1, "Example"),
        rep(1),
        rep(1),
        rep(1),
        rep(1),
        rep(1),
      }
    )
  ),
  s(
    "createZustandStoreProvider",
    fmt(
      [[
import type {{ PropsWithChildren }} from 'react';
import {{ createContext, useContext }} from 'react';
import {{ createStore, useStore }} from 'zustand';
import {{ useShallow }} from 'zustand/react/shallow';
import {{ useStoreWithEqualityFn }} from 'zustand/traditional';

export function create{}StoreProvider<State, InitialStateParam = void>({{
  creator,
  name = '{}',
}}: {{
  creator: Parameters<ReturnType<typeof createStore<State>>>[0];
  name?: string;
}}) {{
  const _createStore = (initialState?: InitialStateParam) =>
    createStore<State>()((set, get, store) => ({{
      ...creator(set, get, store),
      ...initialState,
    }}));
  const Context = createContext<ReturnType<typeof _createStore> | null>(null);
  Context.displayName = name;

  const Provider = (
    props: PropsWithChildren<
      InitialStateParam extends void
        ? {{ initialState?: InitialStateParam }}
        : {{ initialState: InitialStateParam }}
    >,
  ) => {{
    const store = useRefValue(() => _createStore(props.initialState));
    return <Context.Provider value={{store}}>{{props.children}}</Context.Provider>;
  }};

  function useStoreProvider(): State;
  function useStoreProvider<T>(selector: (state: State) => T): T;
  function useStoreProvider<T>(
    selector: (state: State) => T,
    equalityFn: (lhs: T, rhs: T) => boolean,
  ): T;
  function useStoreProvider(selector?: any, equalityFn?: any) {{
    const store = useContext(Context);
    if (!store) {{
      throw new Error(`Missing ${{name}} Provider in the tree`);
    }}
    if (equalityFn) {{
      return useStoreWithEqualityFn(store, selector, equalityFn);
    }} else if (selector) {{
      return useStore(store, selector);
    }} else {{
      return useStore(store);
    }}
  }}

  const useStoreProviderShallow = <T,>(selector: (state: State) => T) => {{
    return useStoreProvider(useShallow(selector));
  }};

  return {{ Provider, useStoreProvider, useStoreProviderShallow, Consumer: Context.Consumer }};
}}
]],
      {
        i(1, "Name"), -- $NAME$
        rep(1),
      }
    )
  ),
}
