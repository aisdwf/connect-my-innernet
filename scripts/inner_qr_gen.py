#!/usr/bin/env python3
"""
[内网传出辅助工具] inner_qr_gen.py
用法：
  python3 scripts/inner_qr_gen.py <要传出的文本文件路径> [--raw]

说明：
  - 将内网的报错日志或代码片段显示为终端二维码（支持自动分段，避免单个二维码过密无法识别）。
  - 默认若文本较长会自动使用 gzip + base64 压缩（外网 Agent 可直接识别还原）；
    若希望手机扫码直接看到明文文字，可加上 --raw 参数（推荐！手机微信/相机扫码后可直接复制文字）。
  - 依赖：内网若安装了 python `qrcode` 库 (`pip install qrcode`) 会直接渲染高精度 ANSI 二维码。
"""

import argparse
import base64
import gzip
import sys
from pathlib import Path


def split_chunks(text: str, chunk_size: int) -> list[str]:
    return [text[i : i + chunk_size] for i in range(0, len(text), chunk_size)]


def print_qr_terminal(data: str) -> None:
    try:
        import qrcode  # type: ignore
    except ImportError:
        print(
            "[提示] 内网尚未安装 python qrcode 库，请先运行:\n"
            "  pip install qrcode -i https://pypi.tuna.tsinghua.edu.cn/simple\n"
            "或者使用 npm 安装:\n"
            "  npm install -g qrcode-terminal\n",
            file=sys.stderr,
        )
        sys.exit(1)

    qr = qrcode.QRCode(
        version=None,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=1,
        border=2,
    )
    qr.add_data(data)
    qr.make(fit=True)
    qr.print_ascii(invert=True)


def main() -> None:
    parser = argparse.ArgumentParser(description="将内网文件或标准输入转为终端二维码")
    parser.add_argument("file", nargs="?", help="要生成二维码的文本文件路径（留空则从 stdin 读取）")
    parser.add_argument(
        "--compress",
        action="store_true",
        help="使用 gzip+base64 压缩（适合大段代码，外网拿到以 GZ64: 开头的字符串后自动解压）",
    )
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=600,
        help="每个二维码的最大字符数（默认 600，保证手机拍摄清晰易识别）",
    )
    args = parser.parse_args()

    if args.file:
        content = Path(args.file).read_text(encoding="utf-8", errors="replace")
    else:
        content = sys.stdin.read()

    content = content.strip()
    if not content:
        print("[错误] 输入内容为空！", file=sys.stderr)
        sys.exit(1)

    if args.compress:
        compressed = gzip.compress(content.encode("utf-8"), compresslevel=9)
        payload = "GZ64:" + base64.b64encode(compressed).decode("ascii")
    else:
        payload = content

    chunks = split_chunks(payload, args.chunk_size)
    total = len(chunks)

    for idx, chunk in enumerate(chunks, start=1):
        print(f"\n================ 二维码 [{idx}/{total}] (长度: {len(chunk)} 字符) ================")
        if total > 1:
            header = f"[{idx}/{total}]\n"
            print_qr_terminal(header + chunk)
        else:
            print_qr_terminal(chunk)
        if idx < total:
            try:
                input(f"--> 请拍照或扫描第 [{idx}/{total}] 张二维码，完成后按 [Enter] 显示下一张...")
            except EOFError:
                break


if __name__ == "__main__":
    main()
