// 运行时错误的JavaScript脚本
console.log("Starting runtime error test");

// 故意制造运行时错误
function causeError() {
    throw new Error("Intentional runtime error");
}

// 尝试调用错误函数
try {
    causeError();
} catch (error) {
    console.error("Caught error:", error.message);
}

// 访问未定义属性
const obj = {};
console.log(obj.nonExistentProperty.someMethod); // 运行时错误
