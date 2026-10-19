#!/usr/bin/env python3
# ==============================================================================
# SOC Lab — Générateur de PDF pour le Rapport Technique et la Présentation
# ==============================================================================

import os
import re

def clean_text(text):
    """Nettoie le texte Markdown pour un rendu PDF propre en police standard Type 1."""
    t = text
    # Remplacement des symboles mathématiques / LaTeX
    t = t.replace(r"$\ge 7$", ">= 7")
    t = t.replace(r"$\ge 12$", ">= 12")
    t = t.replace(r"$\rightarrow$", "->")
    t = t.replace(r"\ge", ">=")
    t = t.replace(r"\le", "<=")
    t = t.replace("$", "")
    
    # Remplacement des apostrophes et tirets typographiques
    t = t.replace("’", "'").replace("‘", "'")
    t = t.replace("“", '"').replace("”", '"')
    t = t.replace("—", " - ").replace("–", " - ")
    t = t.replace("•", "-")
    
    # Suppression du gras Markdown ** ou *
    t = re.sub(r"\*\*(.*?)\*\*", r"\1", t)
    t = re.sub(r"\*(.*?)\*", r"\1", t)
    t = re.sub(r"`(.*?)`", r"\1", t)
    
    return t

def write_pdf(filename, pages_content, landscape=False):
    """
    pages_content: list of pages. Each page is a list of tuples: (font_name, size, x, y, text)
    landscape: True for presentation slides (842 x 595), False for A4 portrait (595 x 842)
    """
    width, height = (842, 595) if landscape else (595, 842)
    
    font_defs = {
        "/F1": "Helvetica",
        "/F2": "Helvetica-Bold",
        "/F3": "Helvetica-Oblique",
        "/F4": "Courier"
    }
    
    font_ids = {}
    next_id = 4
    for fname, base in font_defs.items():
        font_ids[fname] = next_id
        next_id += 1
        
    page_obj_ids = []
    content_obj_ids = []
    objects = [None] * (3 + len(font_defs))
    
    for page_items in pages_content:
        stream_cmds = ["BT"]
        for font, size, x, y, raw_text in page_items:
            clean = clean_text(raw_text)
            escaped = (clean.replace("\\", "\\\\")
                            .replace("(", "\\(")
                            .replace(")", "\\)"))
            stream_cmds.append(f"1 0 0 1 {x} {y} Tm")
            stream_cmds.append(f"{font} {size} Tf")
            stream_cmds.append(f"({escaped}) Tj")
        stream_cmds.append("ET")
        
        stream_data = "\n".join(stream_cmds).encode("latin-1", "replace")
        content_id = len(objects) + 1
        c_obj = f"<< /Length {len(stream_data)} >>\nstream\n".encode("ascii") + stream_data + b"\nendstream"
        objects.append(c_obj)
        content_obj_ids.append(content_id)
        
        page_id = len(objects) + 1
        font_res = " ".join([f"{k} {v} 0 R" for k, v in font_ids.items()])
        p_obj = (f"<< /Type /Page /Parent 3 0 R /MediaBox [0 0 {width} {height}] "
                 f"/Resources << /Font << {font_res} >> >> "
                 f"/Contents {content_id} 0 R >>").encode("ascii")
        objects.append(p_obj)
        page_obj_ids.append(page_id)
        
    kids_str = " ".join(f"{pid} 0 R" for pid in page_obj_ids)
    objects[0] = b"<< /Type /Catalog /Pages 3 0 R >>"
    objects[1] = b"<< /Type /Outlines /Count 0 >>"
    objects[2] = f"<< /Type /Pages /Kids [{kids_str}] /Count {len(page_obj_ids)} >>".encode("ascii")
    
    for i, (fname, base) in enumerate(font_defs.items()):
        f_id = font_ids[fname]
        objects[f_id - 1] = f"<< /Type /Font /Subtype /Type1 /Name {fname} /BaseFont /{base} /Encoding /WinAnsiEncoding >>".encode("ascii")
        
    with open(filename, "wb") as f:
        f.write(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n")
        xref = [0]
        offset = len(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n")
        for i, obj in enumerate(objects):
            xref.append(offset)
            hdr = f"{i+1} 0 obj\n".encode("ascii")
            ftr = b"\nendobj\n"
            f.write(hdr)
            f.write(obj)
            f.write(ftr)
            offset += len(hdr) + len(obj) + len(ftr)
            
        xref_offset = offset
        f.write(b"xref\n")
        f.write(f"0 {len(objects)+1}\n".encode("ascii"))
        f.write(b"0000000000 65535 f \n")
        for pos in xref[1:]:
            f.write(f"{pos:010d} 00000 n \n".encode("ascii"))
            
        f.write(b"trailer\n")
        f.write(f"<< /Size {len(objects)+1} /Root 1 0 R >>\n".encode("ascii"))
        f.write(b"startxref\n")
        f.write(f"{xref_offset}\n".encode("ascii"))
        f.write(b"%%EOF\n")
    print(f"[✓] Fichier généré avec succès : {filename} ({len(page_obj_ids)} pages)")

def build_report_pdf():
    input_md = "/home/pris/projets/livrable-soc-lab/rapport/rapport-soc-lab.md"
    output_pdf = "/home/pris/projets/livrable-soc-lab/rapport/rapport-soc-lab.pdf"
    
    with open(input_md, "r", encoding="utf-8") as f:
        content = f.read()
        
    lines = content.splitlines()
    
    pages = []
    current_page = []
    y = 760
    page_num = 1
    
    def new_page():
        nonlocal current_page, y, page_num
        if current_page:
            # Header
            current_page.append(("/F3", 8, 50, 805, "SecureNet Solutions — Rapport Technique : Déploiement SOC Lab"))
            # Footer
            current_page.append(("/F1", 8, 520, 35, f"Page {page_num}"))
            current_page.append(("/F3", 8, 50, 35, "Confidentiel — Usage Interne & Académique"))
            pages.append(current_page)
            page_num += 1
        current_page = []
        y = 760

    for line in lines:
        line_clean = line.strip()
        if not line_clean:
            y -= 10
            if y < 65:
                new_page()
            continue
            
        if line_clean == "---":
            y -= 14
            if y < 65:
                new_page()
            continue

        if line_clean.startswith("# "):
            if current_page:
                new_page()
            title = line_clean[2:]
            current_page.append(("/F2", 15, 50, y, title))
            y -= 26
        elif line_clean.startswith("## "):
            y -= 14
            if y < 90:
                new_page()
            title = line_clean[3:]
            current_page.append(("/F2", 12, 50, y, title))
            y -= 20
        elif line_clean.startswith("### "):
            y -= 10
            if y < 75:
                new_page()
            title = line_clean[4:]
            current_page.append(("/F2", 10.5, 50, y, title))
            y -= 16
        elif line_clean.startswith("#### "):
            y -= 8
            if y < 65:
                new_page()
            title = line_clean[5:]
            current_page.append(("/F2", 9.5, 50, y, title))
            y -= 15
        elif line_clean.startswith("- ") or line_clean.startswith("* "):
            text = "- " + line_clean[2:]
            while len(text) > 85:
                part = text[:85]
                idx = part.rfind(" ")
                if idx == -1: idx = 85
                current_page.append(("/F1", 9, 65, y, text[:idx]))
                text = "  " + text[idx:].strip()
                y -= 14
                if y < 65: new_page()
            current_page.append(("/F1", 9, 65, y, text))
            y -= 14
        elif line_clean.startswith("|"):
            current_page.append(("/F4", 7.5, 50, y, line_clean))
            y -= 12
        elif line_clean.startswith("```"):
            continue
        elif line_clean.startswith("+--") or line_clean.startswith("|"):
            current_page.append(("/F4", 7.5, 50, y, line_clean))
            y -= 11
        else:
            text = line_clean
            while len(text) > 90:
                part = text[:90]
                idx = part.rfind(" ")
                if idx == -1: idx = 90
                current_page.append(("/F1", 9, 50, y, text[:idx]))
                text = text[idx:].strip()
                y -= 14
                if y < 65: new_page()
            current_page.append(("/F1", 9, 50, y, text))
            y -= 14
            
        if y < 65:
            new_page()
            
    if current_page:
        current_page.append(("/F3", 8, 50, 805, "SecureNet Solutions — Rapport Technique : Déploiement SOC Lab"))
        current_page.append(("/F1", 8, 520, 35, f"Page {page_num}"))
        current_page.append(("/F3", 8, 50, 35, "Confidentiel — Usage Interne & Académique"))
        pages.append(current_page)
        
    write_pdf(output_pdf, pages, landscape=False)

def build_presentation_pdf():
    input_md = "/home/pris/projets/livrable-soc-lab/presentation/presentation.md"
    output_pdf = "/home/pris/projets/livrable-soc-lab/presentation/presentation.pdf"
    
    with open(input_md, "r", encoding="utf-8") as f:
        content = f.read()
        
    slides_raw = content.split("<!-- slide -->")
    pages = []
    
    for slide_idx, s in enumerate(slides_raw):
        s_lines = s.strip().splitlines()
        page_items = []
        y = 530
        
        page_items.append(("/F3", 9, 60, 565, "SOC Lab Infrastructure — SecureNet Solutions | Démonstration Live"))
        page_items.append(("/F1", 9, 740, 35, f"Slide {slide_idx + 1} / {len(slides_raw)}"))
        
        for line in s_lines:
            l = line.strip()
            if not l or l == "---":
                y -= 8
                continue
            if l.startswith("# "):
                title = l[2:]
                page_items.append(("/F2", 18, 60, y, title))
                y -= 32
            elif l.startswith("## "):
                title = l[3:]
                page_items.append(("/F2", 13, 60, y, title))
                y -= 22
            elif l.startswith("- ") or l.startswith("* "):
                bullet = "- " + l[2:]
                page_items.append(("/F1", 11.5, 80, y, bullet))
                y -= 20
            elif l.startswith("  - ") or l.startswith("  * "):
                bullet = "    - " + l[4:]
                page_items.append(("/F1", 10.5, 100, y, bullet))
                y -= 17
            elif l.startswith("    - ") or l.startswith("    * "):
                bullet = "        * " + l[6:]
                page_items.append(("/F1", 10, 120, y, bullet))
                y -= 15
            else:
                page_items.append(("/F1", 11, 80, y, l))
                y -= 18
                
        pages.append(page_items)
        
    write_pdf(output_pdf, pages, landscape=True)

if __name__ == "__main__":
    build_report_pdf()
    build_presentation_pdf()
