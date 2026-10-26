///|
fn web_package_json_t() -> String {
  join_lines([
    "{", "  \"name\": \"web\",", "  \"private\": true,", "  \"type\": \"module\",",
    "  \"scripts\": {", "    \"build\": \"esbuild src/main.jsx --bundle --outfile=../../static/app.js --jsx=automatic --jsx-import-source=preact\"",
    "  },", "  \"dependencies\": {", "    \"preact\": \"^10.19.0\"", "  },", "  \"devDependencies\": {",
    "    \"esbuild\": \"^0.24.0\"", "  }", "}",
  ])
}

///|
fn web_main_jsx_t() -> String {
  join_lines([
    "import { hydrate } from \"preact\";", "import { useState } from \"preact/hooks\";",
    "", "function Counter() {", "  const [count, setCount] = useState(0);", "  const label = `Clicked ${count} ${count === 1 ? \"time\" : \"times\"}`;",
    "  return (", "    <button", "      type=\"button\"", "      class=\"counter\"",
    "      onClick={() => setCount((current) => current + 1)}", "    >", "      {label}",
    "    </button>", "  );", "}", "", "const islands = { counter: Counter };", "",
    "for (const element of document.querySelectorAll(\"[data-island]\")) {", "  const componentName = element.dataset.island;",
    "  const Component = islands[componentName];", "  if (Component) {", "    hydrate(<Component />, element);",
    "  } else {", "    console.warn(`Unknown Preact island: ${componentName}`);",
    "  }", "}",
  ])
}
