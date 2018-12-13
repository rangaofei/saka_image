enum ImageType {
  ///start load placeHolder
  PRE_PLACE_HOLDER,
  /// start process placeholder out animation
  OUT_DURATION,
  /// start process image in animation,this may not trigger
  IN_DURATION,
  ///start process image in animation
  CORRECT_IMAGE,
  ///start load err image
  ERR_PLACE_HOLDER,
}
