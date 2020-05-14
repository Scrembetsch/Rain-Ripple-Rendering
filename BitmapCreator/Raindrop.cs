using System;
using System.Collections.Generic;
using System.Drawing;
using System.Text;

namespace BitmapCreator
{
    public class Raindrop
    {
        public Point Position;
        public int Length;
        public double TimeOffset;

        private double _Sigma = 72.75;
        private double _RhoHeavy = 997;
        public Raindrop()
        {
        }

        public Raindrop(Point position, int length, double timeOffset)
        {
            Position = position;
            Length = length;
            TimeOffset = timeOffset;
        }

        public double GetLength(int x, int y)
        {
            return Math.Sqrt(Math.Pow(Length - x, 2) + Math.Pow(Length - y, 2));
        }

        public int[,] GetRaindropImage(double time)
        {
            double cutoffOffset = 0.5;
            double waves = 20;
            time += TimeOffset;
            time = time % 2;
            int[,] image = new int[Length * 2, Length * 2];
            for(int x = 0; x < image.GetLength(0); x++)
            {
                for(int y = 0; y < image.GetLength(1); y++)
                {
                    double value = GetLength(x, y);
                    if(value > Length)
                    {
                        image[x, y] = 0;
                        continue;
                    }

                    value /= Length;
                    double invValue = value;
                    value = 1 - invValue;

                    if (time > invValue)
                    {
                        if (time > cutoffOffset && (time - cutoffOffset) > invValue)
                        {
                            image[x, y] = 0;
                            continue;
                        }
                    }
                    else
                    {
                        image[x, y] = 0;
                        continue;
                    }
                    double k = invValue * waves;
                    double normDur = time / (1 + cutoffOffset);

                    double output = -1.5 + Math.Sqrt((_Sigma / _RhoHeavy) * Math.Pow(Math.Abs(k), 3));

                    // Create moving
                    output = Math.Sin(output * (Math.PI - (normDur * Math.PI)));
                    output = output * 128 * value;
                    image[x, y] = (int)Math.Round(output);
                }
            }
            return image;
        }
    }
}
