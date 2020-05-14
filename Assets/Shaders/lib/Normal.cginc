#if !defined (NORMAL_INCLUDEDED)
#define NORMAL_INCLUDED

float GetHeightValue(float4 colorValue, float speed, float cutoffOffset, float waves, float noise, float sigma, float rho)
{
    float output = 0;
    float time = (_Time.y + colorValue.g + noise) * speed;
    float invColor = 1 - colorValue.r;
    float duration = time % (1 + cutoffOffset);
    if(duration > invColor)
    {
        if(duration > cutoffOffset && (time - cutoffOffset) % (1 + cutoffOffset) > invColor)
        {
            output = 0;
        }
        else
        {
            output = 1;
        }
    }
    if(output == 0)
    {
        return output;
    }
    // Create duration value between 0 - 1
    float normDur = duration / (1 + cutoffOffset);
    float k = invColor * waves;    // Wave number

    // Calculate waves (Capillary Wave)

    // Water, Air
    // output = sqrt((_Sigma / (_RhoHeavy + _RhoLight)) * pow(abs(k), 3));
    
    // Water, Vacuum
    output = -1.5 + sqrt((sigma / rho) * pow(abs(k), 3));

    // Water, Air, Gravity
    // float part1 = ((_RhoHeavy - _RhoLight) / (_RhoHeavy + _RhoLight)) * _Gravity;
    // float part2 = (_Sigma / (_RhoHeavy + _RhoLight)) * pow(k, 2);
    // output = sqrt(abs(k) * (part1 + part2));

    // Create moving
    output = sin(output * (3.14 - (normDur * 3.14)));

    // Wave should fade out to the end
    output *= colorValue.r * (1 - normDur);
    return output;
}

#endif  // NORMAL_INCLUDED