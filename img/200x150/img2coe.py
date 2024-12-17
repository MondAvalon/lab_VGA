import os
from PIL import Image

# 定义输入和输出目录
input_dir = "./input/"
output_dir = "./output/"

# 确保输出目录存在
os.makedirs(output_dir, exist_ok=True)

# 获取输入目录中的所有图片文件
input_files = [f for f in os.listdir(input_dir) if f.endswith(".png")]

# 设置默认输出尺寸
default_output_width = 200
default_output_height = 150

# 获取用户自定义的输出尺寸
output_size_input = input(
    f"请输入输出图片的尺寸（格式：宽度x高度，例如 {default_output_width}x{default_output_height}，按回车使用默认值）："
)

# 解析用户输入的尺寸
if output_size_input.strip() == "":
    output_width, output_height = default_output_width, default_output_height
else:
    try:
        output_width, output_height = map(int, output_size_input.split("x"))
    except ValueError:
        print(
            f"输入格式错误，请确保按 '宽度x高度' 格式输入。例如：{default_output_width}x{default_output_height}"
        )
        exit(1)

# 循环处理每一张图片
for input_file in input_files:
    # 打开原始图片
    img_raw = Image.open(os.path.join(input_dir, input_file))

    # 获取原始图片尺寸、格式、模式等
    print(f"Original size: {img_raw.size}")
    print(f"Original format: {img_raw.format}")
    print(f"Original mode: {img_raw.mode}")

    # 调整图片尺寸到用户指定的大小
    img = img_raw.resize((output_width, output_height))

    # 如果原图是 RGBA 模式，保持其 RGBA 模式
    if img_raw.mode == "RGBA":
        img = img.convert("RGBA")
    else:
        img = img.convert("RGB")

    # 获取调整后的图片尺寸
    img_w, img_h = img.size
    print(f"Resized image size: {img.size}")

    # 保存调整过的图片
    output_image_path = os.path.join(
        output_dir, os.path.splitext(input_file)[0] + ".png"
    )
    img.save(output_image_path, "PNG")

    # 定义生成 RGB COE 文件的函数
    def generate_rgb_coe(file_path):
        with open(file_path, "w") as file:
            # 写入文件头部信息
            file.write(
                "; RGB COE File\nmemory_initialization_radix=16;\nmemory_initialization_vector=\n"
            )

            # 遍历图片的每个像素并写入 .coe 文件
            for j in range(img_h):
                for i in range(img_w):
                    # 获取每个像素的 RGB 值，忽略 Alpha 通道
                    r, g, b = img.getpixel((i, j))[:3]
                    r, g, b = int(r / 16), int(g / 16), int(b / 16)

                    # 格式化为 12 位 RGB 数据
                    result = "{:03X}".format((r << 8) | (g << 4) | b)
                    file.write(result + " ")

                # 换行
                file.write("\n")
            file.write(";\n")

    # 定义生成 Alpha COE 文件的函数（以二进制格式保存）
    def generate_alpha_coe(file_path):
        with open(file_path, "w") as file:
            file.write(
                "; Alpha COE File\nmemory_initialization_radix=2;\nmemory_initialization_vector=\n"
            )

            for j in range(img_h):
                for i in range(img_w):
                    # 获取 Alpha 值
                    if img.mode == "RGBA":
                        a = img.getpixel((i, j))[3]
                    else:
                        a = 255  # 默认为不透明

                    # 将 Alpha 映射为 1 位 (0 或 1)
                    alpha_bit = "1" if a > 128 else "0"
                    file.write(alpha_bit + " ")

                # 换行
                file.write("\n")
            file.write(";\n")

    # 生成 COE 文件
    output_rgb_coe = os.path.join(
        output_dir, os.path.splitext(input_file)[0] + "_rgb.coe"
    )
    output_alpha_coe = os.path.join(
        output_dir, os.path.splitext(input_file)[0] + "_alpha.coe"
    )

    generate_rgb_coe(output_rgb_coe)
    generate_alpha_coe(output_alpha_coe)

print("处理完成！")
