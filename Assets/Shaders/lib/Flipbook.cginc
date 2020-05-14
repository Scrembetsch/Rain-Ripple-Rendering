#if !defined (FLIPBOOK_INCLUDEDED)
#define FLIPBOOK_INCLUDED

float2 GetAtlasPosition(float2 originalPos, float2 tiling, float tilesPerSecond, float countX, float countY)
{
    float2 noise = GenerateNoise(originalPos, tiling);
    float2 newPos = float2(originalPos.x / countX, originalPos.y / countY);

    float frameNumber = GetIntPart(_Time.y * tilesPerSecond + noise * 100);

    newPos.x = (newPos.x * tiling.x) % (1 / countX);
    newPos.y = (newPos.y * tiling.y) % (1 / countY);
    newPos.x = newPos.x + (1 / countX) * (frameNumber % countX);
    newPos.y = newPos.y + (1 / countY) * GetIntPart(frameNumber / countY);
    newPos.y = 1 - newPos.y;
    return newPos;
}

#endif // FLIPBOOK_INCLUDED