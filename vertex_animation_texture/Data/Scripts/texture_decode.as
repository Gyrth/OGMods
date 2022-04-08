void Init(string level_name){

}

float DecodeFloatRG(vec2 enc){
	vec2 kDecodeDot = vec2(1.0, 1.0 / 255.0);
	return dot(enc, kDecodeDot);
}

vec2 EncodeFloatRG(float v){
	vec2 kEncodeMul = vec2(1.0, 255.0);
	float kEncodeBit = 1.0 / 255.0;
	vec2 enc = kEncodeMul * v;

	enc.x = enc.x % 1;
	enc.y = enc.y % 1;

	enc.x -= enc.y * kEncodeBit;

	return enc;
}

uint combine(uint a, uint b) {
	uint times = 1;
	while (times <= b)
		times *= 10;
	return a*times + b;
}

uint merge(uint int1, uint int2)
{
	uint temp = int2;

	while (temp > 0){
		temp /= 10;
		int1 *= 10;
	}

	return int1 + int2;
}

int combine2(int a, int b)
{
	int times = 1;
	if( b != 0 )
	{
		times = int(pow(10.0, double(((int(log10(double(b))) + 1.0)))));
	}
	return a * times + b ;
}

int GetIndex(vec3 vertex){
	int x_num = int( (vertex.x < 0.0? vertex.x * -1.0 : vertex.x) * 10000.001 );
	int y_num = int( (vertex.y < 0.0? vertex.y * -1.0 : vertex.y) * 10000.001 );
	int z_num = int( (vertex.z < 0.0? vertex.z * -1.0 : vertex.z) * 10000.001 );

	int x_tens = (x_num % 100) / 10;
	int x_units = (x_num % 10);

	int y_tens = (y_num % 100) / 10;
	int y_units = (y_num % 10);

	int z_tens = (z_num % 100) / 10;
	int z_units = (z_num % 10);

	array<int> arr = {x_tens, x_units, y_tens, y_units, z_tens, z_units};
	int result = 0;

	for(uint i = 0 ; i < arr.size() ; i++){
		result = (result * 10) + arr[i];
	}

	return result;
}

//Optional functions in script
void Update(int is_paused){
	
}

void Decoding(){
	vec3 bounds = vec3(5.0, 5.0, 5.0);
	float result = DecodeFloatRG(vec2(0.4980f, 0.5000f));
	/* Log(warning, "Result : " + result); */
	float un_range_adjusted = result * bounds.x;
	float un_origin_adjusted = un_range_adjusted - (bounds.x / 2.0);
	/* Log(warning, "Result adjusted : " + un_origin_adjusted); */

	float position = 0.0f;
	position = position + (bounds.x / 2.0);
	position = position / bounds.x;

	Log(warning, "--------------------");
	Log(warning, "adjusted " + position);
	vec2 encoded = EncodeFloatRG(position);
	Log(warning, "encoded " + encoded.x + "," + encoded.y);
	float decoded = DecodeFloatRG(encoded);
	Log(warning, "decoded " + decoded);

	float decoded_position = decoded * bounds.x;
	decoded_position = decoded_position - (bounds.x / 2.0);
	Log(warning, "decoded decoded_position " + decoded_position);
}
