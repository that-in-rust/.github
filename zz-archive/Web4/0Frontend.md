# **Rust-Native Frontend Library**

_A DOM/CSS/JS-free UI framework built for performance and safety._

---

## **Core Principles**

// Direct pixel manipulation vs DOM updates
// Current: DOM → CSS → Layout → Paint → Composite
// Marauder: Rust → Pixels → Display

🎨 **No DOM**: Render directly to a pixel buffer or GPU (e.g., via `tiny-skia` or `wgpu`).  
🎨 **No CSS**: Styling is type-safe Rust (e.g., structs/enums for layout/paint).  
⚡ **No JavaScript**: Events are Rust closures, compiled to WASM for the browser.  
📜 **Declarative DSL**: Use Rust macros for a React-like syntax, but with compile-time guarantees.

---

## **Architecture**

Split the library into **two parts**:

1. **`core`**:
   - Pure Rust layout/painting/event system.
   - Platform-agnostic (works native/WASM).
2. **`ui`**:
   - DSL macros and high-level components (buttons, grids, etc.).
   - Built on `core`.

---

## **Fresh Approach to UI Components**

### **A. Rendering Model**

- **Immediate Mode** (like `egui`):
  - No retained DOM; redraw every frame.
  - Simpler, but less optimal for static UIs.
- **Retained Mode** (like Qt):
  - Build a **scene graph** of UI nodes.
  - Diff updates for minimal repaints.
- **Hybrid Approach**:
  - Retained mode for static UIs, immediate mode for dynamic parts.

### **B. Layout System**

- **Type-Safe Constraints**:
  ```rust
  struct Layout {
      width: Constraint, // e.g., Constraint::Fill(0.8) or Constraint::Fixed(100)
      height: Constraint,
      padding: EdgeInsets,
  }
  ```
- **Flexbox Alternative**:
  - Use Rust enums for alignment/direction:
    ```rust
    enum Direction { Row, Column }
    enum Alignment { Start, Center, End }
    ```

### **C. Styling**

- **Inline Styles**:
  ```rust
  #[derive(Style)]
  struct ButtonStyle {
      background: Color, // e.g., Color::hex("#FF0000")
      border_radius: f32,
      padding: EdgeInsets,
  }
  ```
- **Theming**:
  - Global theme provider (compile-time or runtime).

### **D. Event Handling**

- **Rust Closures**:
  ```rust
  Button::new("Click me")
      .on_click(|| println!("Clicked!"))
  ```
- **Bubbling/Capturing**:
  - Explicit event propagation (no DOM-like magic).

---

## **Example DSL**

```rust
// ui macro
#[component]
fn Counter() -> impl View {
    let count = use_state(0);
    view! {
        Column {
            Button::new("Increment")
                .on_click(move || count.set(*count + 1)),
            Text::new(format!("Count: {}", *count)),
        }
    }
}
```

---

## **Key Innovations**

### **A. Compile-Time Validation**

- **Invalid UI = Compile Error**:
  - Macros check for missing event handlers or invalid layouts.
  - Example:
    ```rust
    // Error: Missing `on_click` for Button
    Button::new("Broken");
    ```

### **B. GPU-Accelerated (Optional)**

- Use `wgpu` for cross-platform GPU rendering.
- Fallback to CPU (`tiny-skia`) for compatibility.

### **C. Text Rendering**

- Integrate `rustybuzz` (text shaping) + `ab_glyph` (rasterization).
- No browser font APIs; bundle fonts as bytes.

---

## **Backend Integration**

- **Shared State**:
  - Use `serde` to sync state between frontend/backend.
- **SSR (Server-Side Rendering)**:
  - Render UI to pixels on the server, send as image (or diff).

---

## **Example Stack**

| Layer         | Crates/Tools                      |
| ------------- | --------------------------------- |
| **DSL**       | `proc-macro`, `syn`, `quote`      |
| **Layout**    | Custom (no `taffy`)               |
| **Rendering** | `tiny-skia` (CPU) or `wgpu` (GPU) |
| **Text**      | `rustybuzz`, `ab_glyph`           |
| **Events**    | Custom (no `web-sys`)             |
| **WASM**      | `wasm-bindgen` (minimal shim)     |

---

## **Comparison to Existing Rust UI Libs**

| Library | DOM? | CSS? | GPU? | DSL? |
| ------- | ---- | ---- | ---- | ---- |
| Yew     | ✅   | ✅   | ❌   | ❌   |
| Iced    | ❌   | ❌   | ✅   | ❌   |
| \*\*\*  | ❌   | ❌   | ✅   | ✅   |

---

## **Next Steps**

1. **Prototype `core`**:
   - Start with layout/painting (e.g., a `View` trait).
2. **Build the DSL**:
   - Use `proc-macro` for `view!{}` syntax.
3. **Demo**:
   - A "counter app" in native + WASM.

---
