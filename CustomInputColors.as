// Documentation available at https://donadigo.com/tminterface/plugins/api
bool CustomColors = false;
array<string> colorMode = {"Dual Colors","Rainbow"};
string currentMode = "Select a Mode";
SimulationManager@ simManager = GetSimulationManager();
int currentSteer;
int colorSpeed = 2;
vec3 Left;
vec3 Right;
vec3 value1;
vec3 value2;
bool rainbow = false;
bool isSet = false;
bool loop = true;

void OnRunStep(SimulationManager@ simManager)
{
    currentSteer = simManager.GetInputState().Steer;
    if (currentMode == colorMode[0]) {
        bool rainbow = false;
        if (currentSteer >= 0) {
            ExecuteCommand("steer_color " + Math::Abs(Right.x) + "," + Math::Abs(Right.y) + "," + Math::Abs(Right.z));
        } else {
            ExecuteCommand("steer_color " + Math::Abs(Left.x) + "," + Math::Abs(Left.y) + "," + Math::Abs(Left.z));
        }
    } else if (currentMode == colorMode[1]) {
        ExecuteCommand("steer_color " + Math::Abs(Right.x) + "," + Math::Abs(Right.y) + "," + Math::Abs(Right.z));
    }
    
}

void update()
{
    if (Right.x > 255) {
        Right.x = 255;
    }
    if (Right.y > 255) {
        Right.y = 255;
    }
    if (Right.z > 255) {
        Right.z = 255;
    }

    if (Left.x > 255) {
        Left.x = 255;
    }
    if (Left.y > 255) {
        Left.y = 255;
    }
    if (Left.z > 255) {
        Left.z = 255;
    }

    if (value2.x > 255) {
        value2.x = 255;
    }
    if (value2.y > 255) {
        value2.y = 255;
    }
    if (value2.z > 255) {
        value2.z = 255;
    }
    if (value2.x > 255) {
        value2.x = 255;
    }
    if (value2.y > 255) {
        value2.y = 255;
    }
    if (value2.z > 255) {
        value2.z = 255;
    }

    if (value1.x < 0) {
        value1.x = 0;
    }
    if (value1.y < 0) {
        value1.y = 0;
    }
    if (value1.z < 0) {
        value1.z = 0;
    }
    if (value2.x < 0) {
        value2.x = 0;
    }
    if (value2.y < 0) {
        value2.y = 0;
    }
    if (value2.z < 0) {
        value2.z = 0;
    }
}

void loopcolors()
{
    loop = false;
    if (Right.x >= 255 and Right.y >= Right.z) {
        Right.y += colorSpeed;
        loop = false;
    } else if (Right.x >= 255 and Right.y < 1 and Right.z >= 255 and loop) {
        loop = false;
        Right.z -= colorSpeed;
    }

    if (Right.y >= 255) {
        Right.x -= colorSpeed;
    }
    if (Right.x < 1 and Right.y == 255) {
        Right.z += colorSpeed;
    }

    if (Right.z >= 255) {
        Right.y -= colorSpeed;
    }

    if (Right.x >= Right.y and Right.z >= 255) {
        Right.x += colorSpeed;
    }

    if (Right.x >= Right.z and Right.y < 1) {
        loop = true;
        Right.z -= colorSpeed;
    }

    if (Right.x > 255) {
        Right.x = 255;
    } else if (Right.x < 0) {
        Right.x = 0;
    }
    if (Right.y > 255) {
        Right.y = 255;
    } else if (Right.y < 0) {
        Right.y = 0;
    }
    if (Right.z > 255) {
        Right.z = 255;
    } else if (Right.z < 0) {
        Right.z = 0;
    }
}

void Render()
{
    update();

    if (rainbow and CustomColors) {
        loopcolors();
    }

    if (UI::Begin("Custom Input Display Colors")) {
        if (CustomColors = UI::Checkbox("Active", CustomColors)){
            CustomColors = true;
            if (UI::BeginCombo("Color Mode", currentMode))
            {
                for (uint i = 0; i < colorMode.Length; i++)
                {
                    const string color = colorMode[i];
                    if (UI::Selectable(color, color == currentMode)) {
                        currentMode = color;
                    }
                }

                UI::EndCombo();
            }
            if (currentMode == colorMode[0]) { // Dual Colors
                isSet = false;
                rainbow = false;
                UI::DragFloat3("Left", value1);
                UI::DragFloat3("Right", value2);
                if (UI::Button("Apply")) {
                    Left = value1;
                    Right = value2;
                }
            } else if (currentMode == colorMode[1]) {
                rainbow = true;
                if (rainbow and !isSet) {
                    isSet = true;
                    Right.x = 255;
                    Right.y = 0;
                    Right.z = 0;
                }
                colorSpeed = UI::SliderInt("Speed", colorSpeed, 2, 10);
            }
        }
    }
    UI::End();
}

void Main()
{
    log("Plugin started.");
}

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Custom Input Colors";
    info.Author = "Gl1tch3D";
    info.Version = "v1.0.0";
    info.Description = "Adds Muli-Color to the Input Display.";
    return info;
}
