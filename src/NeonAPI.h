#pragma once

class NeonAPI
{
private:
	static bool api_installed;
	static HMODULE hapi;
	static RwTexture* neon_texture;

	class NeonData {
    public:
		CRGBA color;
        bool neon_installed;
		float val;
		uint timer;
		bool increment;

        NeonData(CVehicle *pVeh) 
		{ 
			neon_installed = false; 
			val = 0.0;
			timer = 0;
			increment = true;
		}
    };

    static VehicleExtendedData<NeonData> VehNeon;

public:
	NeonAPI();
	~NeonAPI();
	static void InstallNeon(CVehicle *veh, int red, int green, int blue);
	static bool IsNeonInstalled(CVehicle *veh);
	static void RemoveNeon(CVehicle *veh);
};

