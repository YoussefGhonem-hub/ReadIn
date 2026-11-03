/** `.txt` files are bundled as strings (angular.json → `loader`), e.g. the deny-lists in `shared/security`. */
declare module '*.txt' {
  const content: string;
  export default content;
}
