// Documentation available at https://donadigo.com/tminterface/plugins/api
bool customColors = false;
const array<string> colorMode = { "Dual Colors", "Rainbow" };
string currentMode = "Select a Mode";
int colorSpeed = 2;
vec3 left;
vec3 right;
vec3 value1;
vec3 value2;
bool rainbow = false;
bool isSet = false;
bool loop = true;
CommandList colorChanger;

SimulationManager@ simManager = GetSimulationManager();

void OnRunStep(SimulationManager@ simManager)
{
}

void changesteercolor() {
    int currentSteer = simManager.GetInputState().Steer;
    bool kbright = simManager.GetInputState().Right;
    bool kbleft = simManager.GetInputState().Left;
    if (currentMode == colorMode[0] and customColors) {
        bool rainbow = false;
        if (currentSteer > 0 or kbright and !kbleft) {
            log("steering right");
            colorChanger.Content = "steer_color " + Math::Abs(right.x) + "," + Math::Abs(right.y) + "," + Math::Abs(right.z);
        } else if (currentSteer < 0 or kbleft and !kbright){
            log("steering left");
            colorChanger.Content = "steer_color " + Math::Abs(left.x) + "," + Math::Abs(left.y) + "," + Math::Abs(left.z);
        }
    } else if (currentMode == colorMode[1]) {
        colorChanger.Content = "steer_color " + Math::Abs(right.x) + "," + Math::Abs(right.y) + "," + Math::Abs(right.z);
    } else {
        return;
    }

    colorChanger.Process();
}


void update()
{
    left.x = Math::Min(left.x, 255.f);
    left.y = Math::Min(left.y, 255.f);
    left.z = Math::Min(left.z, 255.f);
    right.x = Math::Min(right.x, 255.f);
    right.y = Math::Min(right.y, 255.f);
    right.z = Math::Min(right.z, 255.f);

    value1.x = Math::Clamp(value1.x, 0.f, 255.f);
    value1.y = Math::Clamp(value1.y, 0.f, 255.f);
    value1.z = Math::Clamp(value1.z, 0.f, 255.f);
    value2.x = Math::Clamp(value2.x, 0.f, 255.f);
    value2.y = Math::Clamp(value2.y, 0.f, 255.f);
    value2.z = Math::Clamp(value2.z, 0.f, 255.f);
}

void loopcolors()
{
    loop = false;
    if (right.x >= 255 and right.y >= right.z) {
        right.y += colorSpeed;
        loop = false;
    } else if (right.x >= 255 and right.y < 1 and right.z >= 255 and loop) {
        loop = false;
        right.z -= colorSpeed;
    }

    if (right.y >= 255) {
        right.x -= colorSpeed;
    }
    if (right.x < 1 and right.y == 255) {
        right.z += colorSpeed;
    }

    if (right.z >= 255) {
        right.y -= colorSpeed;
    }

    if (right.x >= right.y and right.z >= 255) {
        right.x += colorSpeed;
    }

    if (right.x >= right.z and right.y < 1) {
        loop = true;
        right.z -= colorSpeed;
    }

    right.x = Math::Clamp(right.x, 0.f, 255.f);
    right.y = Math::Clamp(right.y, 0.f, 255.f);
    right.z = Math::Clamp(right.z, 0.f, 255.f);
}

void Render(SimulationManager@ simManager)
{
    update();
    changesteercolor();
    if (rainbow and customColors) {
        loopcolors();
    }
}

void Window()
{
    customColors = UI::Checkbox("Active", customColors);
    if (!customColors)
        return;
    UI::PushItemWidth(200);
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
        UI::DragFloat3("left", value1);
        UI::DragFloat3("right", value2);
        if (UI::Button("Apply")) {
            left = value1;
            right = value2;
        }
        UI::Text("Left Steer color " + Math::Abs(left.x) + "," + Math::Abs(left.y) + "," + Math::Abs(left.z));
        UI::Text("Right Steer color " + Math::Abs(right.x) + "," + Math::Abs(right.y) + "," + Math::Abs(right.z));
        
    } else if (currentMode == colorMode[1]) {
        rainbow = true;
        if (rainbow and !isSet) {
            isSet = true;
            right.x = 255;
            right.y = 0;
            right.z = 0;
        }
        colorSpeed = UI::SliderInt("Speed", colorSpeed, 2, 10);
    }
}

void Main()
{
    RegisterSettingsPage("Custom Input Colors", Window);
}

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Custom Input Colors";
    info.Author = "Gl1tch3D";
    info.Version = "v1.1.0";
    info.Description = "Adds Multi-Color to the Input Display.";
    return info;
}
