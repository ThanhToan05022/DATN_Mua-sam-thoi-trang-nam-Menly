export type Cursor = {
  v: number | string;
  id: string;
};

export interface PageInfo {
  limit: number;
  hasNext: boolean;
  nextCursor: string | null;
}

export interface Page<T> {
  items: T[];
  pageInfo: PageInfo;
}
