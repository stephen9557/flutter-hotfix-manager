// 模拟网络错误的脚本
console.log("Testing network error handling");

// 模拟网络请求失败
function simulateNetworkError() {
    return new Promise((resolve, reject) => {
        setTimeout(() => {
            reject(new Error("Network timeout"));
        }, 1000);
    });
}

// 测试网络错误处理
simulateNetworkError()
    .then(result => {
        console.log("Network request successful:", result);
    })
    .catch(error => {
        console.error("Network error caught:", error.message);
    });
