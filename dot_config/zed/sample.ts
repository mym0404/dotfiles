export const helloSchema = z.object({});
export type hello = z.infer<typeof helloSchema>;
