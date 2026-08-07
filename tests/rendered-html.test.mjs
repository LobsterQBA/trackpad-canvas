import assert from "node:assert/strict";
import test from "node:test";

const productPath = "/projects/trackpad-canvas";

async function render(path = productPath) {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}-${path}`);
  const { default: worker } = await import(workerUrl.href);

  return worker.fetch(
    new Request(`http://localhost${path}`, {
      headers: { accept: "text/html" },
    }),
    {
      ASSETS: {
        fetch: async () => new Response("Not found", { status: 404 }),
      },
    },
    {
      waitUntil() {},
      passThroughOnException() {},
    },
  );
}

test("renders the Trackpad Canvas product page", async () => {
  const response = await render();
  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type") ?? "", /^text\/html\b/i);

  const html = await response.text();
  assert.match(html, /Your trackpad is the canvas/i);
  assert.match(html, /Download for macOS/i);
  assert.match(html, /Create/);
  assert.match(html, /Refine/);
  assert.match(html, /Present/);
  assert.match(html, /prefers-reduced-motion|Trackpad Canvas/);
  assert.match(html, /\/_vercel\/insights\/script\.js/);
  assert.doesNotMatch(html, /codex-preview|react-loading-skeleton/i);
});

test("renders privacy and license pages", async () => {
  const [privacy, license] = await Promise.all([
    render(`${productPath}/privacy`),
    render(`${productPath}/license`),
  ]);
  assert.equal(privacy.status, 200);
  assert.equal(license.status, 200);
  assert.match(await privacy.text(), /local-first macOS application/i);
  assert.match(await license.text(), /Trackpad Studio attribution/i);
});
