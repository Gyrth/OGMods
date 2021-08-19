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

//Optional functions in script
void Update(int is_paused){
	vec3 bounds = vec3(5.0, 5.0, 5.0);
	float result = DecodeFloatRG(vec2(0.4980f, 0.5000f));
	/* Log(warning, "Result : " + result); */
	float un_range_adjusted = result * bounds.x;
	float un_origin_adjusted = un_range_adjusted - (bounds.x / 2.0);
	/* Log(warning, "Result adjusted : " + un_origin_adjusted); */

	float position = 0.0f;
	position = position + (bounds.x / 2.0);
	position = position / bounds.x;

	Log(warning, "adjusted " + position);
	vec2 encoded = EncodeFloatRG(position);
	Log(warning, "encoded " + encoded.x + "," + encoded.y);
	float decoded = DecodeFloatRG(encoded);
	Log(warning, "decoded " + decoded);

	float decoded_position = decoded * bounds.x;
	decoded_position = decoded_position - (bounds.x / 2.0);
	Log(warning, "decoded decoded_position " + decoded_position);
}
