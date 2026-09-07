const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const Node = { TEXT_NODE: 3, ELEMENT_NODE: 1 };

function text(value) {
  return { nodeType: Node.TEXT_NODE, textContent: value };
}

function field(title, value) {
  return {
    nodeType: Node.ELEMENT_NODE,
    textContent: value,
    getAttribute: name => name === "title" ? title : ""
  };
}

function courseDiv(childNodes, className = "kbcontent") {
  return {
    className,
    childNodes,
    textContent: childNodes.map(node => node.textContent).join(" ")
  };
}

function cell(divs = []) {
  return {
    textContent: divs.map(div => div.textContent).join(" "),
    querySelectorAll: selector => {
      const className = selector.replace("div.", "");
      return divs.filter(div => div.className === className);
    }
  };
}

const mixedCell = courseDiv([
  text("机器学习"),
  field("老师", "梁老师"),
  field("周次", "1-16周（双）"),
  field("节次", "[0910节]"),
  field("教室", "B座502"),
  text("--------------------"),
  text("计算机安全"),
  field("老师", "陈老师"),
  field("周次", "1-16周（单）"),
  field("节次", "[0910节]"),
  field("教室", "B座502"),
  text("────────────"),
  text("创新创业导论"),
  field("老师", "徐老师"),
  field("周次", "1周（单）"),
  field("节次", "[0910节]"),
  field("教室", "B座214")
]);

const header = {
  textContent: "节次 星期日 星期一 星期二 星期三 星期四 星期五 星期六"
};
const row = {
  cells: [
    { textContent: "9-10节" },
    cell(),
    cell(),
    cell(),
    cell([mixedCell]),
    cell(),
    cell(),
    cell()
  ]
};
const scheduleTable = { rows: [header, row] };
const document = {
  querySelectorAll: selector => selector === "table" ? [scheduleTable] : [],
  querySelector: selector => selector === "#xnxq01id"
    ? { value: "2026-2027-1" }
    : null
};

const scriptPath = path.join(
  __dirname,
  "..",
  "assets",
  "scripts",
  "CsuExtractScript.js"
);
const result = JSON.parse(
  vm.runInNewContext(fs.readFileSync(scriptPath, "utf8"), { document, Node })
);

assert.equal(result.term, "2026-2027-1");
assert.equal(result.courses.length, 3);
assert.deepEqual(
  result.courses.map(course => course.name),
  ["机器学习", "计算机安全", "创新创业导论"]
);
assert.deepEqual(result.courses[0].weekInterval, [2, 4, 6, 8, 10, 12, 14, 16]);
assert.deepEqual(result.courses[1].weekInterval, [1, 3, 5, 7, 9, 11, 13, 15]);
assert.deepEqual(result.courses[2].weekInterval, [1]);
assert.ok(result.courses.every(course => course.period.join(",") === "9,10"));
assert.ok(result.courses.every(course => !/^[-─]+$/.test(course.name)));

console.log("CSU extraction fixture passed: 3 split courses, no separator artifacts.");
