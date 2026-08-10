export default {
  async fetch(request, env, ctx) {
    return new Response("hello from the edge", {
      headers: { "content-type": "text/plain" },
    });
  },
};
