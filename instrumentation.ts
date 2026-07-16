/**
 * Next.js-ის ოფიციალური "instrumentation" hook — გაეშვება ერთხელ,
 * სერვერის პროცესის დაწყებისთანავე (არა ყოველ request-ზე). იდეალური
 * ადგილია startup-ის ვალიდაციისთვის, სანამ პირველი request საერთოდ
 * მოვა.
 *
 * საჭიროებს `experimental.instrumentationHook` არ სჭირდება Next.js
 * 15-ში — ეს ფუნქციონალი უკვე stable-ია.
 */
export async function register() {
  // მხოლოდ Node.js runtime-ზე (არა Edge) — validateEnv() უბრალო
  // synchronous შემოწმებაა, მაგრამ ეს გვარდი საჭიროა, რადგან
  // instrumentation.ts ორივე runtime-ზე გაშვება შეიძლება.
  if (process.env.NEXT_RUNTIME === "nodejs") {
    const { validateEnv } = await import("@/lib/env");
    validateEnv();
  }
}
