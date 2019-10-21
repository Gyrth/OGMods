# Comic Creator

The Comic Creator lets you create dynamic comics inside Overgrowth. These comics can be saved, loaded and played back in the Comic Reader as well as in-game. This could also be used to create cutscenes which are better told using images.

## Basics
To create a new comic simply go to ``Play -> Comic Creator``. An empty sheet will be created for you with a grid. The list of available functions are under the menu button ``Add``. The Comic Creator will execute these function in order, starting at the top. Once enough functions are added you can change the order by drag and dropping the correct function at the correct line. Most of the functions have settings available. To edit these settings, double click the function you want to edit. If you would like to preview the comic press ``F1`` to toggle the editor on and off.

## Functions

### Crawl In
The Crawl In function is only used on text. Once this function is executed it will find the previous Text function and slowly reveal the text one character at a time. This can be interrupted by the user by pressing either mouse button to either skip or reset the Crawl In. There are two settings in the ``Settings`` tab that have an effect on this function. ``Text Sounds`` plays a sound effect when text is being added similar to the dialogue system in Overgrowth. ``Text Sound Variant`` is an option to change the sound effect to a selected few. This function also has a ``Duration`` setting which is how long the Crawl In should take in milliseconds.

### Fade In
To reveal a piece of text or an image the Fade In function can be used. This function will retrieve the previous ``Text`` or ``Image`` function and apply a Fade In. In the settings the duration can be set of the fade in milliseconds. The Tween Type is an option that modifies the fade to appear different.

### Font
When a Font function is added, all the text after it will be effected by this function until another Font function is found. This has a few options that can change your Comic drastically. The first option is to pick a font. Note that only ``.ttf`` files are supported by Overgrowth. The second option is to pick a font color. Either enter an HTML color code or click the colored square to use the color picker. The shadowed option either shows or hides the shadow at the back of each text. This will not work when the text is rotated however. The last option is the text size. There is a limit of 100, but by using ``Ctrl + LMB`` on the slider the value can be overridden.

### Image
Arguably the most important function in the Comic Creator. By default the Overgrowth logo will be shown and ready to be edited. To move the image click and drag somewhere on the image. The round icons at the corners of the image can be used to scale the image. Scaling the image can also be used to invert/mirror the image. Scaling and positioning the image are locked to the grid using the snap scale set under the ``Settings`` button. The function has a few options, changing the image file to begin with. The supported files are ``.png``, ``.jpg``, ``.tga`` and `.dds`. The sliders for position and scale can be used for more precise transformations. The offsets in both scale and position can be used to "cut out" a part of an image. This way images can be reused but show something different. The rotation setting can be used to rotate the image in degrees. The color option is used to tint the image. Note that it's adding color to the colors on the image. So tinting black has no effect for example. Keep aspect ration makes sure that the original size is held in account when it comes to scaling. This means the image can not be stretched incorrectly.

### Move In
The Move In has an effect on both images and text elements. It searched for the previous element and makes it move into the right position. The first option is the duration. This is how long the Move In takes in milliseconds. The second option is the offset. This is the added position from the origin. And lastly the Tween Type is used to make the Move In look a bit different.

### Music
This function can be used to add music to the comic. It uses the build-in music system that Overgrowth has. Just load a music XML file that follows the Overgrowth specifications and it's songs can be used by the ``Song`` function. An example of a music XML is ``Data/Music/lugaru.xml``.

### Page


### Song

### Sound

### Text

### Wait Click

### Wait

[Preorder the game here.](http://www.wolfire.com/overgrowth)
