export function id(){
  // quick unique-ish id for demo
  return Math.random().toString(36).slice(2) + Date.now().toString(36)
}
