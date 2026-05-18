// Custom editor for rendering mode dropdown (place in Editor folder)
#if UNITY_EDITOR
using UnityEngine;
using UnityEditor;

public class EmoteDisplaysShaderGUI : ShaderGUI
{
    public enum RenderMode
    {
        Opaque,
        Cutout,
        Fade,
        Transparent
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        Material material = materialEditor.target as Material;
        
        // Find properties
        MaterialProperty mainTex = FindProperty("_MainTex", properties);
        MaterialProperty emissiveColor = FindProperty("_EmissiveColor", properties);
        MaterialProperty emissiveStrength = FindProperty("_EmissiveStrength", properties);
        MaterialProperty pixelCountX = FindProperty("_PixelCountX", properties);
        MaterialProperty pixelCountY = FindProperty("_PixelCountY", properties);
        MaterialProperty roundness = FindProperty("_Roundness", properties);
        MaterialProperty fuzziness = FindProperty("_Fuzziness", properties);
        MaterialProperty cutoff = FindProperty("_Cutoff", properties);
        MaterialProperty srcBlend = FindProperty("_SrcBlend", properties);
        MaterialProperty dstBlend = FindProperty("_DstBlend", properties);
        MaterialProperty zWrite = FindProperty("_ZWrite", properties);
        MaterialProperty alphaToMask = FindProperty("_AlphaToMask", properties);
        
        // Render mode dropdown
        RenderMode mode = RenderMode.Opaque;
        if (material.GetFloat("_SrcBlend") == (float)UnityEngine.Rendering.BlendMode.SrcAlpha &&
            material.GetFloat("_DstBlend") == (float)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha)
        {
            if (material.GetFloat("_ZWrite") == 0 && material.GetFloat("_AlphaToMask") == 0)
                mode = RenderMode.Fade;
            else if (material.GetFloat("_ZWrite") == 1 && material.GetFloat("_AlphaToMask") == 1)
                mode = RenderMode.Transparent;
            else
                mode = RenderMode.Fade; // fallback
        }
        else if (material.GetFloat("_SrcBlend") == (float)UnityEngine.Rendering.BlendMode.One &&
                 material.GetFloat("_DstBlend") == (float)UnityEngine.Rendering.BlendMode.Zero)
        {
            mode = RenderMode.Opaque;
        }
        else if (material.GetFloat("_SrcBlend") == (float)UnityEngine.Rendering.BlendMode.One &&
                 material.GetFloat("_DstBlend") == (float)UnityEngine.Rendering.BlendMode.Zero &&
                 material.GetFloat("_AlphaToMask") == 1)
        {
            mode = RenderMode.Cutout;
        }
        
        EditorGUI.BeginChangeCheck();
        mode = (RenderMode)EditorGUILayout.EnumPopup("Rendering Mode", mode);
        if (EditorGUI.EndChangeCheck())
        {
            switch (mode)
            {
                case RenderMode.Opaque:
                    material.SetFloat("_SrcBlend", (float)UnityEngine.Rendering.BlendMode.One);
                    material.SetFloat("_DstBlend", (float)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetFloat("_ZWrite", 1);
                    material.SetFloat("_AlphaToMask", 0);
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Geometry;
                    break;
                case RenderMode.Cutout:
                    material.SetFloat("_SrcBlend", (float)UnityEngine.Rendering.BlendMode.One);
                    material.SetFloat("_DstBlend", (float)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetFloat("_ZWrite", 1);
                    material.SetFloat("_AlphaToMask", 1);
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
                    break;
                case RenderMode.Fade:
                    material.SetFloat("_SrcBlend", (float)UnityEngine.Rendering.BlendMode.SrcAlpha);
                    material.SetFloat("_DstBlend", (float)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    material.SetFloat("_ZWrite", 0);
                    material.SetFloat("_AlphaToMask", 0);
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                    break;
                case RenderMode.Transparent:
                    material.SetFloat("_SrcBlend", (float)UnityEngine.Rendering.BlendMode.SrcAlpha);
                    material.SetFloat("_DstBlend", (float)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    material.SetFloat("_ZWrite", 1);
                    material.SetFloat("_AlphaToMask", 1);
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
                    break;
            }
        }
        
        // Draw the rest of properties
        materialEditor.ShaderProperty(mainTex, mainTex.displayName);
        EditorGUILayout.Space();
        materialEditor.ShaderProperty(emissiveColor, emissiveColor.displayName);
        materialEditor.ShaderProperty(emissiveStrength, emissiveStrength.displayName);
        EditorGUILayout.Space();
        materialEditor.ShaderProperty(pixelCountX, "Pixel Count X");
        materialEditor.ShaderProperty(pixelCountY, "Pixel Count Y");
        materialEditor.ShaderProperty(roundness, roundness.displayName);
        materialEditor.ShaderProperty(fuzziness, fuzziness.displayName);
        
        if (mode == RenderMode.Cutout || mode == RenderMode.Transparent)
        {
            materialEditor.ShaderProperty(cutoff, "Alpha Cutoff");
        }
        
        // Hidden properties not normally shown
        materialEditor.ShaderProperty(srcBlend, "");
        materialEditor.ShaderProperty(dstBlend, "");
        materialEditor.ShaderProperty(zWrite, "");
        materialEditor.ShaderProperty(alphaToMask, "");
    }
}
#endif