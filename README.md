# Tessellated Minimap – Real-Time 3D Holographic Minimap for VRChat

This project provides a complete, avatar‑integrated solution for a **real‑time tessellated 3D holographic minimap** in VRChat. Using custom Unity shaders and dual render textures, the minimap dynamically displays elevation data from your avatar’s environment – turning a flat surface into a true 3D, height‑based map.

---

## ✨ Features

- **Real‑time environment capture** – The minimap updates live as your avatar moves through a world.
- **Tessellation‑driven 3D deformation** – Mesh geometry is subdivided and displaced by depth data, creating realistic elevation changes (hills, structures, etc.) instead of a flat 2D representation.
- **Dual‑camera render texture system** – Separate colour and depth cameras supply isolated visual and height data streams for optimal shader processing.
- **Virtual height map workaround** – A proprietary depth‑to‑height conversion method that is stable, performant, and VRChat‑friendly (no real‑time lighting hacks).
- **Fully tunable** – Adjust tessellation rate, displacement strength, render scale, and range via VRChat radial puppets (optional).
- **Ready‑to‑use shaders** – Includes `Minimap.shader` and `Virtual Height Map.shader` with full source code.

---

## 📐 What is Tessellation?

In computer graphics, **tessellation** subdivides a mesh surface into smaller polygons (triangles) in real time. When combined with a **height map** (grayscale data where white = high, black = low), tessellation displaces the newly created vertices along their normals.  

For this minimap, tessellation reads depth‑derived height data and physically raises or lowers sections of the map mesh – producing a genuine **3D topographic relief** rather than a flat texture. The result is a layered, holographic display that reacts to the actual geometry around your avatar.

---

## 📺 Full Tutorial

For a complete step‑by‑step setup guide (avatar hierarchy, camera placement, render textures, shader coding, and virtual height map configuration), please check the **YouTube link in my GitHub profile**.

---

## ⚙️ Requirements

- Unity **2019.4.31f1** or later (VRChat SDK3 compatible)
- VRChat SDK3 – Avatars
- Basic familiarity with Unity editor, shader editing, and avatar hierarchy

---

## ❓ Troubleshooting

| Issue | Likely Fix |
|-------|-------------|
| Flat minimap (no elevation) | Check depth camera projection: **perspective** is required. Verify render texture resolution ≥ 1024px. |
| Visual noise / flickering | Increase depth texture resolution or adjust depth camera’s near/far planes. |
| Poor performance | Lower tessellation rate or reduce render texture resolution (512px). |

---

## 📜 License

This project is released under the **MIT License** – use it freely in both personal and commercial avatars, with attribution appreciated.
