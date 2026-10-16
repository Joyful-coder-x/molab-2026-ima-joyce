# Swift Syntax & Concept Notes

配套：`GameRoomLearning.swift`。英文 topic / keyword，中文解释。

## Run Guide

1. 在 Xcode 创建 **iOS → App**：Interface 选 SwiftUI，Language 选 Swift；最低部署版本设为 **iOS 17.0** 或更高。
2. 删除新 project 自动生成的 `ContentView.swift` 和 `项目名App.swift`；加入 `GameRoomLearning.swift`，确认 Target Membership 勾选 app target。
3. 本文件已经包含 `@main`、Home 和两个游戏。**不要同时加入旧版八个文件**，否则会重复定义或有两个入口。
4. 选 iPhone Simulator，按 **Command-R**。Catch 点击球；Fall 默认用拖动模式。
5. 真机测试 Tilt：Target → Info → Custom iOS Target Properties，添加 **Privacy - Motion Usage Description**（`NSMotionUsageDescription`），值可填 `Use device motion to move the ball in the Fall game.`。连接 iPhone，配置 Signing，然后运行；Fall 中在开始前打开 **Use Tilt**。
6. Settings 修改时长；先选 30 秒方便测试。声音使用 system sound，不需要音频文件；设备静音、系统设置或 Simulator 可能影响可听效果。

验证边界：生成环境为 Linux，没有 Swift/Xcode。完成 tree-sitter Swift 语法解析（无 syntax error）及源码结构检查；这不等于编译。未执行 Apple SDK type-check、Simulator 或真机测试；首次运行以 Xcode 的编译和运行结果为准。

## Learning Map

| Topic | 原代码 | 配套代码 | When to choose this version |
|---|---|---|---|
| History ownership | 每个游戏自己 `load()` | App 创建一个 `GameHistory` | 多个页面要共同修改一份数据时 |
| Observable model | static enum store | `@Observable final class` | 需要有身份、可观察的共享状态时 |
| Data delivery | 通过参数传 results 数组 | environment 共享 history | 多层级、多页面需要相同对象时；显式参数仍适合小型结构 |
| Editable child | 无 reusable 编辑控件 | `@Binding DurationPicker` | 子控件需要修改父级拥有的值时 |
| Editable model | 无 observable 表单 | `@Bindable RoundOptions` | 表单控件需要 `$model.property` 时 |
| Preferences | 无保存的声音设置 | `@AppStorage` | 小型偏好需要跨启动保存时 |
| Persistence | JSON Data → UserDefaults | JSON Data → Documents 文件 | 记录集合需要独立文件管理时 |
| Round state | 两个 Bool | `RoundPhase` enum | 状态互斥、有明确阶段时 |
| Fall timing | 两个 Timer | 一个 async task loop | 工作跟随页面生命周期、需要取消时 |

结构只按职责改变，不按文件数量改变：`GameHistory` 负责共享历史，`RoundOptions` 负责可编辑时长，`MotionInput` 管理传感器服务；仍在一个 Swift 文件内。两个 game 的球位置、分数等继续用局部 `@State`。

行为差异：打开 Results、离开游戏或 app 进入非 active 状态会结束当前局并保存一次；不是暂停。Catch 范围限制在 board 内；不再绘制原来的扩大范围框。Fall 提供拖动模式并避开在中心生成洞。历史记录提前结束时保存实际时长。

## How to Read a Declaration

下面的 `Type`、`name`、`expression` 是占位说明，不是要原样输入的代码。

```swift
// Stored property
[access] [wrapper] let/var name: Type = initialValue
// Example
@State private var score: Int = 0

// Function / Method
[access] func name(externalLabel internalName: Type) async throws -> ReturnType {
    // body
}
// async、throws、-> ReturnType 都是按需要出现，不是每个函数都要写。

// Struct / Class
[access] struct TypeName: ProtocolA, ProtocolB { /* properties + methods */ }
[access] final class TypeName { /* properties + methods */ }

// View
struct ExampleView: View {
    var body: some View { Text("Hello") }
}
```

`@State` 是 **property wrapper**，`@Observable` 是 **macro**，`@MainActor` 是 actor isolation attribute；它们虽然都以 `@` 开头，但不是同一类机制。`@Observation` 不是这里的用法；正确的是 `import Observation` + `@Observable`。

## Property / Data Syntax

| Category | Keyword / API | Name / Object | Syntax template | Meaning / When |
|---|---|---|---|---|
| Declaration | `let` | 常量名 | `let name: Type = value` | 初始化后不能重新赋值；若值是 class reference，对象的 var 属性仍可修改 |
| Declaration | `var` | 变量名 | `var name: Type = value` | 可以改变值 |
| Type inference | inferred type | 变量名 | `var score = 0` | 编译器推断 Int；不是动态类型 |
| Access | `private` | 属性/函数 | `private var score = 0` | 限定实现细节的访问范围 |
| Access | `private(set)` | 属性 | `private(set) var results: [GameResult] = []` | 外部可读，只有内部能写 |
| Computed property | `var` + body | 属性 | `var total: Int { values.count }` | 每次访问按规则计算，不是另存一份数据 |
| Local state | `@State` | 属性 | `@State private var score = 0` | View 身份保持期间保留状态；更新可触发 UI |
| Binding | `@Binding` | 子 View 属性 | `@Binding var seconds: Int` | 不创建原始数据，连接外部读写位置 |
| Binding projection | `$` | 已有属性 | `DurationPicker(seconds: $duration)` | 给需要 Binding 的参数传连接，不是普通值 |
| Observable model | `@Observable` | class | `@Observable final class Model { var score = 0 }` | 让属性访问和变化可被追踪；不是硬盘保存 |
| Model ownership | `@State` | model instance | `@State private var model = Model()` | 在 View/App 中保留自己创建的 observable 对象 |
| Bindable model | `@Bindable` | model property | `@Bindable var options: RoundOptions` | 从 observable 对象得到 `$options.duration` |
| Environment injection | `.environment` | model instance | `RootView().environment(history)` | 向后代提供对象；需提供正确类型实例 |
| Environment lookup | `@Environment` | model property | `@Environment(GameHistory.self) private var history` | 从祖先读取对象；缺失时可能在运行期失败 |
| System environment | `@Environment` | system value | `@Environment(\.scenePhase) private var scenePhase` | key path 形式读取系统环境值 |
| Saved preference | `@AppStorage` | 属性 | `@AppStorage("key") private var enabled = true` | UserDefaults 中的简单偏好；true 是默认值 |
| Value type | `struct` | 类型名 | `struct Ball: Identifiable { ... }` | 复制后为独立值；适合记录、坐标等 |
| Reference type | `class` | 类型名 | `final class History { ... }` | 多个引用可指向同一对象 |
| Inheritance restriction | `final` | class/method | `final class History { ... }` | 禁止继承；不是禁止修改属性 |
| Enumeration | `enum` / `case` | 类型/枚举值 | `enum Phase { case ready, playing, finished }` | 表达有限、互斥状态 |
| Identity | `Identifiable` | struct/class | `let id = UUID()` | 列表需要稳定身份；不是每次 body 重算生成新 id |
| Serialization | `Codable` | struct/class | `struct Result: Codable { ... }` | Encodable + Decodable；属性类型也须可编码 |
| Array | `[Type]` | 集合 | `var items: [GameResult] = []` | 有序、同类型元素 |
| Dictionary | `[Key: Value]` | 字典 | `var scores: [String: Int] = [:]` | 按 key 查值；下标读取通常得到 Optional |
| Optional | `Type?` / `nil` | 属性/返回值 | `var startedAt: Date? = nil` | 可能没有值 |
| Main actor | `@MainActor` | 类型/函数 | `@MainActor final class History { ... }` | 隔离 UI 相关状态；不是“自动转后台运行” |

## Function / Control Flow Syntax

| Keyword / API | Signature / Example | 中文说明 |
|---|---|---|
| Method | `func add(score: Int) { ... }` | 调用 `add(score: 3)`；无返回值时省略 `-> Void` |
| Return | `func double(_ n: Int) -> Int { n * 2 }` | 调用 `double(3)`；`_` 省略外部 label，内部仍叫 n |
| External/internal names | `func catchBall(at index: Int) { ... }` | 调用 `catchBall(at: 0)`；函数内部用 index |
| Initializer | `init(score: Int) { self.score = score }` | 创建实例；init 不写返回类型 |
| Default argument | `init(id: UUID = UUID()) { ... }` | 调用时可省略 id |
| Static method | `static func load() -> [Result] { ... }` | 用 `Store.load()` 调用；新版实例方法用 `history.add(...)` |
| Guard | `guard condition else { return }` | 不满足前提就提前退出；else 必须离开当前作用域 |
| Optional binding | `if let value = optional { ... }` | 在内部安全使用解包后的值 |
| Optional shorthand | `guard let value else { return }` | value 已存在时可省略 `= value` |
| Nil fallback | `optional ?? fallback` | 没有值时使用默认值 |
| Optional chaining | `object?.method()` | 对象不存在则不执行 |
| Ternary | `condition ? first : second` | 二选一表达式 |
| Loop | `for i in balls.indices { ... }` | 遍历当前有效下标 |
| While | `while condition { ... }` | 条件成立期间反复执行 |
| Enum selection | `switch phase { case .ready: ...; case .playing: ...; case .finished: ... }` | 按枚举状态分支；穷尽所有情况 |
| Closure | `{ parameter in expression }` | 可作为参数传递的代码块 |
| Trailing closure | `Button("Start") { startRound() }` | 最后的 closure 参数可放在括号后 |
| Shorthand closure | `results.filter { $0.gameID == "ball" }` | `$0` 是第一个 closure 参数；不是 `$state` binding |
| Capture list | `{ [weak self] value in ... }` | closure 不强持有 self；适用于避免循环引用 |
| Error propagation | `func load() throws -> Data { ... }` | 函数可能抛错，调用方处理 |
| Error handling | `do { let value = try operation() } catch { ... }` | 捕获失败并报告；`error` 是 catch 内的错误 |
| Optional try | `try? operation()` | 把失败转换为 nil；简单但容易隐藏原因 |
| Async function | `func runRound() async { ... }` | 函数可能挂起 |
| Await | `await runRound()` | 等待异步操作；不代表新建线程 |
| Async + throws | `try await Task.sleep(for: .milliseconds(100))` | sleep 可挂起，取消时抛错 |
| Cancellation | `Task.isCancelled` | 协作式检查取消；不是强制杀死线程 |
| Actor task | `Task { @MainActor in ... }` | 显式在 MainActor 执行异步任务体 |
| Key path | `\.element.id` | 引用属性路径；不是取某个现有对象的属性值 |

## SwiftUI View Syntax

| API | Syntax template | 中文说明 |
|---|---|---|
| View body | `var body: some View { ... }` | computed property；some View 表示一个具体但隐藏的 View 类型 |
| Vertical layout | `VStack(spacing: 16) { ... }` | 垂直排列 |
| Horizontal layout | `HStack { ...; Spacer(); ... }` | 水平排列、Spacer 占剩余空间 |
| Layer layout | `ZStack { ... }` | 后写的 View 叠在前面的上方 |
| Scroll | `ScrollView { ... }` | 内容过高时可滚动 |
| List | `List { Section("Title") { ... } }` | 列表和分区 |
| Repetition | `ForEach(results) { result in ... }` | 元素符合 Identifiable |
| Index repetition | `ForEach(balls.indices, id: \.self) { i in ... }` | 使用下标身份；当前球数组长度和顺序固定才适合这种写法 |
| Text interpolation | `Text("Score: \(score)")` | 把值插入字符串 |
| Button | `Button("Start") { startRound() }` | 点击执行 action |
| Toggle | `Toggle("Sound", isOn: $enabled)` | 参数需要 Binding<Bool> |
| Picker | `Picker("Duration", selection: $seconds) { Text("60").tag(60) }` | tag 类型应与 selection 匹配 |
| Navigation container | `NavigationStack { HomeView() }` | 提供导航上下文 |
| Destination | `NavigationLink("Results") { ResultsView(gameID: nil) }` | 声明入口和目标页面 |
| Modifier | `Circle().fill(.blue).frame(width: 50, height: 50)` | 修饰后的结果又是 View；顺序可能改变布局和效果 |
| Offset | `.offset(x: ball.x, y: ball.y)` | 视觉移动，不改变原来的布局占位 |
| Animation | `withAnimation(.linear(duration: 1)) { x = 100 }` | 动画展示一次状态变化；不自动反复调用函数 |
| Tap | `.onTapGesture { score += 1 }` | 点击手势 |
| Drag | `.gesture(DragGesture().onChanged { value in ... })` | value.location 是该手势坐标空间的位置 |
| Task lifecycle | `.task(id: roundID) { await runRound() }` | View 出现启动，id 改变重新启动，消失取消 |
| Appear/disappear | `.onDisappear { finishRound() }` | View 生命周期回调；不等于对象 deinit |
| Change observation | `.onChange(of: scenePhase) { old, new in ... }` | 这里使用 iOS 17 的双参数形式 |
| Preview | `#Preview { NavigationStack { HomeView() }.environment(GameHistory()) }` | Preview 也要提供所需环境对象 |

## Storage / Motion / Timing APIs

| API | Signature pattern | 中文说明 |
|---|---|---|
| Encode | `try JSONEncoder().encode(value)` | Swift 值 → Data |
| Decode | `try JSONDecoder().decode([GameResult].self, from: data)` | Data → 指定类型；`.self` 传的是类型值 |
| Read file | `try Data(contentsOf: url)` | 文件 → Data |
| Write file | `try data.write(to: url, options: .atomic)` | Data → 文件；小文件同步调用，大文件应异步设计 |
| Documents | `FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]` | app sandbox 内的 Documents 目录 |
| Append path | `directory.appendingPathComponent("gameHistory.json")` | 构造子文件 URL |
| UserDefaults | `UserDefaults.standard.data(forKey: "savedGameResults")` | 读取旧版编码数据；不同 app sandbox 不共享 |
| Date difference | `Date().timeIntervalSince(startTime)` | 实际经过的秒数，不依赖 tick 次数 |
| Timer (old) | `Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in ... }` | callback 模型；结束时 `timer.invalidate()` |
| Motion | `manager.startDeviceMotionUpdates(to: .main) { motion, error in ... }` | 开启设备姿态数据回调；真机能力与权限要检查 |
| Motion stop | `manager.stopDeviceMotionUpdates()` | 页面离开或回合结束时关闭 |
| Sound | `AudioServicesPlaySystemSound(1104)` | 保留你原来的系统声音方案 |
| Random | `CGFloat.random(in: -100...100)` | 闭区间；区间端点必须有效 |
| Distance | `hypot(x, y)` | 二维距离 |
| Direction | `atan2(y, x)` | 方向弧度；注意 y/x 参数顺序 |

## Important Comparisons

- **`@State` vs `@Observable`**：前者管理 View 拥有的状态，后者让 model 可观察；可以一起用，不是二选一。
- **`@Binding` vs `@Bindable`**：前者代表一个值的读写连接，后者为 observable 对象属性生成这类连接。
- **`let` vs binding**：let 可接收新的输入值，但子 View 不能借它直接写回父状态；需要写回才用 binding。
- **Parameter vs environment**：都是依赖传递；参数更显式，environment 减少逐层转交。Environment 不保存到磁盘。
- **Struct vs class**：不同页面各自的 struct 值可独立变化；class 引用可指向同一个实例。共享 class 不代表线程安全。
- **UserDefaults vs JSON**：不在同一层。JSON 是编码格式，UserDefaults/文件是存储方式；旧代码已经使用 JSON。
- **`@Observable` vs old `ObservableObject`**：老师旧示例可能出现 `@Published`、`@StateObject`、`@ObservedObject`、`@EnvironmentObject`；本版本统一用 iOS 17 Observation，不要机械混用。
- **Router vs NavigationLink**：Router 适合集中管理复杂跳转；不是所有 app 必需。本版本保留已有层级导航；Router 未在此版本实现。
- **Shared model vs many files**：class/struct 分开是概念边界，不要求每个类型一个文件。项目变大后才考虑拆文件。

## Experiments

1. Settings 改成 30 秒，玩一局；完全关闭 app 再打开，时长回到 60，而 Sound 设置仍保留。对比运行期状态与持久化偏好。
2. Catch 和 Fall 各完成一局，去 All Results。所有页面读同一 history，而不是分别 load 的副本。
3. 临时把 `DurationPicker` 的 `@Binding` 改成 `let`，观察 Picker 为什么拿不到可写的 `$seconds`。看完恢复，不要保留编译错误。
4. 阅读 `SettingsView`：把 `@Bindable` 改成 `let`，比较 `$options.duration` 的使用为何失效。恢复后再跑。
5. Preview 暂时去掉 `.environment(GameHistory())`，进入 Results，观察缺少依赖的问题；恢复后再继续。
6. 玩到中途打开 Status：应保存一次并结束该局；回来可 Play Again。后台切换也应结束；不要把它理解成 pause。
7. 退出重开验证 history 留存。新建 app 不应期待读到另一个 project 的 UserDefaults；迁移只针对同一 app sandbox。

## Validation Checklist

- [ ] Xcode 编译通过；没有 duplicate main/type 错误。
- [ ] Catch 计分、每 3 次升级、倒计时结束只能保存一次。
- [ ] Fall 拖动能得分；真机 Tilt 可启停，离开后停止传感器。
- [ ] Settings 的声音选择跨启动保留，duration 为 session-only。
- [ ] 两种游戏的 history 混合保存、按类型过滤正确。
- [ ] app 重开后可以读取 JSON；不存在文件时正常显示空历史。
- [ ] 页面返回、打开 Results、后台切换没有留下运行中的回合。

## Sources

课程 Week 4: https://github.com/molab-itp/content-2026-ima/blob/main/weeks/04_swiftui.md

课程 Week 5: https://github.com/molab-itp/content-2026-ima/blob/main/weeks/05_data.md

课程 Week 6: https://github.com/molab-itp/content-2026-ima/blob/main/weeks/06_data.md

Apple Observation: https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app

Apple Bindable: https://developer.apple.com/documentation/swiftui/bindable

Apple AppStorage: https://developer.apple.com/documentation/swiftui/appstorage

以上为学习参考入口；`@MainActor` 和迁移/错误保护属于本版本补充说明，不标为课程必学内容。
