#pragma once

#define BOTTOM_BAR_HEIGHT 44.0f
#define SEND_BUTTON_WIDTH 60.0f
#define IN_MESSAGE_PADDING 5.0f
#define OUT_MESSAGE_PADDING 15.0f
#define PROFILE_PICTURE_SIZE 25.0f

static int GetProfilePictureSize() {
	return PROFILE_PICTURE_SIZE;
}

int ScaleByDPI(int size);
