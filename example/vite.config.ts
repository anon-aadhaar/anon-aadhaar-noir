import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import topLevelAwait from "vite-plugin-top-level-await";
import { nodePolyfills } from "vite-plugin-node-polyfills";
import { viteStaticCopy } from "vite-plugin-static-copy";

export default defineConfig({
  plugins: [
    react(),
    topLevelAwait(),
    nodePolyfills({ include: ["buffer"] }),
    viteStaticCopy({
      targets: [
        {
          src: "node_modules/@noir-lang/acvm_js/web/acvm_js_bg.wasm",
          dest: "node_modules/.vite/deps/",
        },
        {
          src: "node_modules/@noir-lang/noirc_abi/web/noirc_abi_wasm_bg.wasm",
          dest: "node_modules/.vite/deps/",
        },
      ],
    }),
  ],
  server: {
    headers: {
      // Enable SharedArrayBuffer
      "Cross-Origin-Opener-Policy": "same-origin",
      "Cross-Origin-Embedder-Policy": "require-corp",
    },
  },
});
