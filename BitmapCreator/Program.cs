using System;
using System.Collections;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace BitmapCreator
{
    class Program
    {
        static async Task Main(string[] args)
        {
            do
            {
                Console.WriteLine("0 -> Create new image");
                Console.WriteLine("1 -> Create image with random green channels");
                Console.WriteLine("2 -> Clear green channel");
                Console.WriteLine("3 -> Create Radial");
                Console.Write("Select mode:");
                int mode = int.Parse(Console.ReadLine());

                switch (mode)
                {
                    case 0:
                        CreateImage();
                        break;
                    case 1:
                        MakeGreenImage();
                        break;
                    case 2:
                        ClearGreenChannel();
                        break;
                    case 3:
                        await CreateRadial();
                        break;
                    default:
                        Environment.Exit(0);
                        break;
                }
            } while (false);
        }

        public static void CreateImage()
        {
            Console.Write("Image name: ");
            string imageName = Console.ReadLine();
            var image = new Bitmap(256, 256);
            for (int i = 0; i < image.Width; i++)
            {
                for (int j = 0; j < image.Height; j++)
                {
                    image.SetPixel(i, j, Color.FromArgb(255, 255 - i, 0, 0));
                }
            }
            string path = Environment.CurrentDirectory + "/../../../../Assets/Textures/" + imageName + ".png";
            image.Save(path, ImageFormat.Png);
        }

        public static void MakeGreenImage()
        {
            Console.Write("Image name: ");
            string imageName = Console.ReadLine();
            //string imageName = "Radial_2";
            var oImage = new Bitmap(Environment.CurrentDirectory + "/../../../../Assets/Textures/" + imageName + ".png");
            var image = new Bitmap(oImage.Width, oImage.Height);
            for (int i = 0; i < image.Width; i++)
            {
                for (int j = 0; j < image.Height; j++)
                {
                    image.SetPixel(i, j, oImage.GetPixel(i, j));
                }
            }
            Random rng = new Random();
            for (int i = 0; i < image.Width; i++)
            {
                for (int j = 0; j < image.Height; j++)
                {
                    if (image.GetPixel(i, j).R != 0 && image.GetPixel(i, j).G == 0)
                    {
                        int green = CheckSurroundingPixels(ref image, i, j);
                        green = green != 0 ? green : rng.Next(1, 255);

                        GreenSurroundingPixels(ref image, green, i, j, 0);
                        //Console.WriteLine(green);
                    }
                }
                //Console.WriteLine("Progress:" + (float)i / (float)image.Width + "%");
            }
            string path = Environment.CurrentDirectory + "/../../../../Assets/Textures/" + imageName + "_.png";
            image.Save(path, ImageFormat.Png);
        }

        public static int CheckSurroundingPixels(ref Bitmap image, int width, int height)
        {
            int radius = 2;
            int green = 0;
            width--;
            for (int i = width - 2; i <= image.Width; i++)
            {
                for (int j = height - radius / 2; j < height + radius / 2; j++)
                {
                    if (i < 0 || i >= image.Width || j < 0 || j >= image.Height)
                    {
                        continue;
                    }
                    if (image.GetPixel(i, j).R != 0)
                    {
                        green = image.GetPixel(i, j).G;
                    }
                    if (green != 0)
                    {
                        return green;
                    }
                }
            }
            return green;
        }

        public static void GreenSurroundingPixels(ref Bitmap image, int green, int width, int height, int depth)
        {
            if (depth > 1000)
            {
                return;
            }
            depth++;
            if (width < 0 || width >= image.Width || height < 0 || height >= image.Height)
            {
                return;
            }
            //Console.WriteLine(width + ", " + height + ": " + image.GetPixel(width, height).ToString());
            Color color = image.GetPixel(width, height);
            if (color.R != 0 && color.G == 0)
            {
                color = Color.FromArgb(color.A, color.R, green, color.B);
                image.SetPixel(width, height, color);

                GreenSurroundingPixels(ref image, green, width - 1, height - 1, depth);
                GreenSurroundingPixels(ref image, green, width - 1, height, depth);
                GreenSurroundingPixels(ref image, green, width - 1, height + 1, depth);

                GreenSurroundingPixels(ref image, green, width, height - 1, depth);
                GreenSurroundingPixels(ref image, green, width, height + 1, depth);

                GreenSurroundingPixels(ref image, green, width + 1, height - 1, depth);
                GreenSurroundingPixels(ref image, green, width + 1, height, depth);
                GreenSurroundingPixels(ref image, green, width + 1, height + 1, depth);
            }
        }

        public static void ClearGreenChannel()
        {
            Console.Write("Image name: ");
            string imageName = Console.ReadLine();
            //string imageName = "Radial_2";
            var oImage = new Bitmap(Environment.CurrentDirectory + "/" + imageName + ".png");
            var image = new Bitmap(oImage.Width, oImage.Height);
            for (int i = 0; i < image.Width; i++)
            {
                for (int j = 0; j < image.Height; j++)
                {
                    image.SetPixel(i, j, oImage.GetPixel(i, j));
                }
            }
            for (int i = 0; i < image.Width; i++)
            {
                for (int j = 0; j < image.Height; j++)
                {
                    if (image.GetPixel(i, j).G != 0)
                    {
                        Color imageColor = image.GetPixel(i, j);
                        Color color = Color.FromArgb(imageColor.A, imageColor.R, 0, imageColor.B);
                        image.SetPixel(i, j, color);
                        //Console.WriteLine(i + ", " + j + ": " + imageColor);
                    }
                }
            }
            image.Save(Environment.CurrentDirectory + "/" + imageName + "_clear.png");
        }

        public static void MakeRadial(ref Random r, ref Bitmap image, Point point, int size, int mode)
        {
            int green = r.Next(0, 255);
            int step = 255 / size;
            int counter = 0;
            for (int i = 255; i >= 0; i -= step)
            {
                for (float j = 0; j < Math.PI * 2; j += (float)1 / image.Width)
                {
                    Point n = new Point(0, 0);
                    n.X = (image.Width + point.X + (int)Math.Round(Math.Sin(j) * counter)) % image.Width;
                    n.Y = (image.Height + point.Y + (int)Math.Round(Math.Cos(j) * counter)) % image.Height;

                    Color orgColor = image.GetPixel(n.X, n.Y);
                    Color newColor = Color.FromArgb(255, orgColor.R != 0 ? (orgColor.R + i) / 2 : i, green, orgColor.B);
                    switch (mode)
                    {
                        case 0:
                            image.SetPixel(n.X, n.Y, Color.FromArgb(255, newColor.R, orgColor.G, orgColor.B));
                            break;

                        case 1:
                            image.SetPixel(n.X, n.Y, Color.FromArgb(255, orgColor.R, newColor.G, orgColor.B));
                            break;

                        case 2:
                            image.SetPixel(n.X, n.Y, Color.FromArgb(255, newColor.R, newColor.G, orgColor.B));
                            break;
                    }
                }
                counter++;
            }
        }

        public static async Task<bool> CreateRadial()
        {
            Random r = new Random();
            Console.Write("Result image name: ");
            string imageName = Console.ReadLine();
            Console.Write("Save as atlas(y/n):");
            bool saveAsAtlas = Console.ReadLine() == "y" ? true : false;

            int width = 8;
            int height = 8;

            int fps = 32;
            int frames = width * height;

            Bitmap[] images = new Bitmap[frames];
            Task[] tasks = new Task[frames];
            DateTime start = DateTime.Now;
            DateTime lastStep = start;
            // Make image black
            int k = 0;
            int size = 1024;
            for(k = 0; k < frames; k++)
            {
                images[k] = new Bitmap(size, size);
            }
            k = 0;
            foreach (Bitmap image in images)
            {
                tasks[k] = Task.Run(() =>
                {
                    for (int x = 0; x < image.Width; x++)
                    {
                        for (int y = 0; y < image.Height; y++)
                        {
                            image.SetPixel(x, y, Color.Gray);
                        }
                    }
                });
                Interlocked.Increment(ref k);
            }
            Task.WaitAll(tasks);
            Console.WriteLine("Created images: " + string.Format("{0:N2}", (DateTime.Now - lastStep).TotalSeconds) + "s");
            Raindrop[] raindrops = new Raindrop[r.Next(5, 10)];
            for(int i = 0; i < raindrops.Length; i++)
            {
                int length = r.Next(25, Math.Min(200, images[0].Width / 2));
                raindrops[i] = new Raindrop(new Point(r.Next(length, images[0].Width - length), r.Next(length, images[0].Height - length)), length, r.NextDouble() * 2);
            }
            lastStep = DateTime.Now;
            k = 0;
            foreach (Bitmap image in images)
            {
                int time = k;
                tasks[k] = Task.Run(() =>
                {
                    int index = 0;
                    for(index = 0; index < images.Length; index++)
                    {
                        if(image == images[index])
                        {
                            break;
                        }
                    }
                    foreach (Raindrop raindrop in raindrops)
                    {
                        int[,] pixels = raindrop.GetRaindropImage((1 / (double)fps) * index);
                        int left = (image.Width + raindrop.Position.X - (pixels.GetLength(0) / 2)) % image.Width;
                        int up = (image.Height + raindrop.Position.Y - (pixels.GetLength(1) / 2)) % image.Height;
                        for (int x = 0; x < pixels.GetLength(0); x++)
                        {
                            for (int y = 0; y < pixels.GetLength(1); y++)
                            {
                                if (pixels[x, y] != 0)
                                {
                                    int xPos = (image.Width + left + x) % image.Width;
                                    int yPos = (image.Height + up + y) % image.Height;
                                    Color oldColor = image.GetPixel(xPos, yPos);
                                    int newColorValue = pixels[x, y];
                                    if (oldColor != Color.Gray)
                                    {
                                        newColorValue = Math.Clamp(oldColor.R - newColorValue, 0, 255);
                                    }
                                    image.SetPixel(xPos, yPos, Color.FromArgb(255, newColorValue, newColorValue, newColorValue));
                                }
                            }
                        }
                    }
                    //images[index] = Filter(images[index], 3);
                });
                Interlocked.Increment(ref k);
            }
            Task.WaitAll(tasks);
            Console.WriteLine("Created raindrop images: " + string.Format("{0:N2}", (DateTime.Now - lastStep).TotalSeconds) + "s");
            lastStep = DateTime.Now;
            if (saveAsAtlas)
            {
                Bitmap atlas = new Bitmap(images[0].Width * width, images[0].Height * height);
                //for (int x = 0; x < atlas.Width; x++)
                //{
                //    for (int y = 0; y < atlas.Height; y++)
                //    {
                //        atlas.SetPixel(x, y, Color.Black);
                //    }
                //}
                //Console.WriteLine("Initalized atlas: " + string.Format("{0:N2}", (DateTime.Now - lastStep).TotalSeconds) + "s");
                //lastStep = DateTime.Now;
 
                for (int i = 0; i < images.Length; i++)
                {
                    for (int x = 0; x < images[i].Width; x++)
                    {
                        for (int y = 0; y < images[i].Height; y++)
                        {
                            int globalX = x + ((i % width) * images[i].Width);
                            int globalY = y + ((i / height) * images[i].Height);

                            atlas.SetPixel(globalX, globalY, images[i].GetPixel(x, y));
                        }
                    }
                }
                string path = Environment.CurrentDirectory + "/../../../../Assets/Textures/" + imageName + ".png";
                //string path = Environment.CurrentDirectory + "/" + imageName + ".png";
                atlas.Save(path, ImageFormat.Png);
                Console.WriteLine("Saved atlas: " + string.Format("{0:N2}", (DateTime.Now - lastStep).TotalSeconds) + "s");
            }
            else
            {
                k = 0;
                foreach (Bitmap image in images)
                {
                    string path = Environment.CurrentDirectory + "/" + imageName + "_" + k++ + ".png";
                    image.Save(path, ImageFormat.Png);
                }
                Console.WriteLine("Saved all images: " + string.Format("{0:N2}", (DateTime.Now - lastStep).TotalSeconds) + "s");
            }
            Console.WriteLine("Total duration: " + string.Format("{0:N2}", (DateTime.Now - start).TotalSeconds) + "s");
            return true;
        }

        private static Bitmap Filter(Bitmap image, int blurSize)
        {
            return Filter(image, new Rectangle(0, 0, image.Width, image.Height), blurSize);
        }

        private unsafe static Bitmap Filter(Bitmap image, Rectangle rectangle, int blurSize)
        {
            Bitmap filtered = new Bitmap(image.Width, image.Height);

            // make an exact copy of the bitmap provided
            using (Graphics graphics = Graphics.FromImage(filtered))
                graphics.DrawImage(image, new Rectangle(0, 0, image.Width, image.Height),
                    new Rectangle(0, 0, image.Width, image.Height), GraphicsUnit.Pixel);

            // Lock the bitmap's bits
            BitmapData blurredData = filtered.LockBits(new Rectangle(0, 0, image.Width, image.Height), ImageLockMode.ReadWrite, filtered.PixelFormat);

            // Get bits per pixel for current PixelFormat
            int bitsPerPixel = Image.GetPixelFormatSize(filtered.PixelFormat);

            // Get pointer to first line
            byte* scan0 = (byte*)blurredData.Scan0.ToPointer();

            // look at every pixel in the blur rectangle
            for (int xx = rectangle.X; xx < rectangle.X + rectangle.Width; xx++)
            {
                for (int yy = rectangle.Y; yy < rectangle.Y + rectangle.Height; yy++)
                {
                    int avgR = 0, avgG = 0, avgB = 0;
                    int blurPixelCount = 0;

                    // average the color of the red, green and blue for each pixel in the
                    // blur size while making sure you don't go outside the image bounds
                    for (int x = xx; (x < xx + blurSize && x < image.Width); x++)
                    {
                        for (int y = yy; (y < yy + blurSize && y < image.Height); y++)
                        {
                            // Get pointer to RGB
                            byte* data = scan0 + y * blurredData.Stride + x * bitsPerPixel / 8;

                            avgB += data[0]; // Blue
                            avgG += data[1]; // Green
                            avgR += data[2]; // Red

                            blurPixelCount++;
                        }
                    }

                    avgR = avgR / blurPixelCount;
                    avgG = avgG / blurPixelCount;
                    avgB = avgB / blurPixelCount;

                    // now that we know the average for the blur size, set each pixel to that color
                    for (int x = xx; x < xx + 1 && x < image.Width && x < rectangle.Width; x++)
                    {
                        for (int y = yy; y < yy + 1 && y < image.Height && y < rectangle.Height; y++)
                        {
                            // Get pointer to RGB
                            byte* data = scan0 + y * blurredData.Stride + x * bitsPerPixel / 8;

                            // Change values
                            data[0] = (byte)avgB;
                            data[1] = (byte)avgG;
                            data[2] = (byte)avgR;
                        }
                    }
                }
            }

            // Unlock the bits
            filtered.UnlockBits(blurredData);

            return filtered;
        }
    }
}
