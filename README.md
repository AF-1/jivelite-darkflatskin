Dark Flat Skin
====

A skin[^1] for jivelite with a different look, extra information on the *Now Playing* screen (rating, year, status icons, audio meta data, lyrics) and the option to rate a track directly on the *Now Playing* screen.<br><br>
For devices running **piCorePlayer**, **SqueezePlay** and **SB Touch**[^2].<br><br>
> **⚠ IMPORTANT: about *updating* ⚠**<br>
> **Before** you update the applet, please read the section on **how to [update](#updating-to-a-newer-version) *Dark Flat Skin* properly**, i.e. use the skin's (un)installer.

<br>

[⬅️ **Back to the list of all plugins**](https://github.com/AF-1/)
<br><br><br>

## Features

- display **more information on the Now Playing screen**(s):
	- **rating** and year

	- **status icons**

		- <img src="DarkFlatSkin/ images/NowPlaying/hq_1.png" width="29px"> = is *lossless*
		- <img src="DarkFlatSkin/ images/NowPlaying/lyrics_1.png" width="23px"> = has *lyrics*
		- <img src="DarkFlatSkin/ images/NowPlaying/csst_1.png" width="23px"> = has a *custom start/stop time* that the [**CSST** plugin](https://github.com/AF-1/lms-customstartstoptimes#custom-start-stop-times) can use
		- <img src="DarkFlatSkin/ images/NowPlaying/remote_1.png" width="28px"> = is a *remote* track (replaced by streaming service icon if track is part of the LMS library)
	- **audio meta data** (content type, bitrate, sample rate/size)
	- NowPlaying screen with **lyrics** (*SqueezePlay* and *piCorePlayer*)<br>

- **easy way to install and uninstall** the skin using an **installer applet**<br>

- **rate** the current track **directly on the Now Playing screen** ([*Ratings Light*](https://github.com/AF-1/#-ratings-light) plugin required)

- option to replace the Shuffle and Repeat buttons with (half-star) rating buttons

- colored track title if the track's comment tag contains a user-specified keyword<br>

- different look (flat, dark)<br>
<br>

This skin comes with the usual VU meters and the default spectrum visualizer. If you're more interested in VU meters and spectrum visualizers, there are other, more suitable skins.<br>

The settings are split between **Settings > Screen > Now Playing** and **Settings > Screen > Dark Flat Skin**.
<br><br><br>

## Screenshots[^3]

<img src="screenshots/dfs-1.jpg" width="100%"><br><br>
<img src="screenshots/dfs-2.jpg" width="100%"><br><br>
<img src="screenshots/dfs-3.jpg" width="100%"><br><br>
<img src="screenshots/dfs-4.jpg" width="100%"><br><br>
<img src="screenshots/dfs-5.jpg" width="100%"><br><br>
<img src="screenshots/dfs-6.jpg" width="100%"><br><br><br><br>
**Grid skin (home menu) - piCorePlayer only**<br><br>
<img src="screenshots/dfs-7.jpg" width="100%"><br><br>

<br><br><br>


## Installation

**First** you install the skin *installer* applet which you will **then** use to install the *skin*.<br>

#### #1 - Get the installer

- Make sure that your LMS and your device have internet access.<br>

- Go to **Settings > Advanced > Applet Installer**.<br>

- Select and install the **Dark Flat Skin Installer**. Then:<br>

	- **piCorePlayer**: restart jivelite by using the **Quit** button.<br>

	- **SqueezePlay**: quit and restart SqueezePlay manually.

	- **SB Touch**: your device will reboot automatically.<br><br>

#### #2 - Install the skin

- You should see a new menu item called **Dark Flat Skin Installer**.<br>

- Follow the menu instructions. To complete the installation:

	- **piCorePlayer**: jivelite will **restart** automatically. Does not require a pCP reboot.<br>

	- **SqueezePlay**: quit and restart SqueezePlay manually.<br>

	- **SB Touch**: your device will reboot automatically.<br><br>

#### #3 - Enable the Dark Flat Skin

- Go to **Settings > Screen > Select skin** to enable the Dark Flat Skin.

- Browse the FAQ article headlines on this page.

<br><br><br>


## Updating to a newer version

- ⚠ **Uninstall the old version first** using the skin's own uninstaller (**Settings > Advanced > Uninstall Dark Flat Skin**), **NOT** *Settings > Advanced > Applet Installer* (see *Uninstalling* section below).

- Then go to **Settings > Advanced > Applet Installer** to install the latest version (see *Installing* section above).

<br><br><br>


## Uninstalling the skin

- Enable a *different* skin.

- Go to **Settings > Advanced > Uninstall Dark Flat Skin** and follow the menu instructions.

	- **piCorePlayer**: jivelite will **restart** automatically. No reboot necessary.<br>

	- **SqueezePlay**: quit and restart SqueezePlay manually.<br>

	- **SB Touch**: your device will reboot automatically.<br><br>

<br><br><br><br>

## FAQ

<details><summary>»<b>I've used the <i>Applet Installer</i> to install/update the <i>Dark Flat Skin Installer</i> but there's <i>no menu item</i> with this name.</b>«</summary><br><p>
The most likely reason is that you had a previous version of <i>Dark Flat Skin</i> on your device. Before you install a new/updated version, please <b>uninstall the previous version first</b>: <i>Settings > Advanced > Uninstall Dark Flat Skin</i>.
</p></details><br>

<details><summary>»<b>I can't open the <i>Screen > NowPlaying > NowPlaying Views</i> menu.</b>«</summary><br><p>
This is a jivelite quirk that's not tied to any skin in particular. Just <b>enter the NowPlaying screen</b> using the top right note icon. Then go back and try again. That usually solves it. If not, make sure that you have selected a player and that this player is connected.
</p></details><br>

<details><summary>»<b>How do I switch to next NowPlaying screen from the <i>lyrics</i> NowPlaying screen?</b>«</summary><br><p>
You need to click/touch the <b>track title in the title bar</b>. The lyrics (text) cannot be used for that because you can scroll up or down in the song lyrics using click-hold/touch-hold.
</p></details><br>

<details><summary>»<b>Clicking/touching the stars on the NowPlaying screen does not change the rating. Why?</b>«<br>»<b>How Do I <b>un</b>rate a track on the NowPlaying screen?</b>«<br>»<b>How do I change the track rating by half a star on the NowPlaying screen?</b>«</summary><br><p>
To rate a track directly on the Now Playing screen, the <b>track must be part of the LMS library</b> (applies to local and remote/online tracks). And you need the <a href="https://github.com/AF-1/#-ratings-light"><b>Ratings Light</b></a> plugin. Make sure the Now Playing screen setting <i>Rate tracks directly on screen</i> is enabled.<br><br>
To <b><i>un</i>rate</b> a track click/touch the space to the left or right of the rating stars. Since the space to the <i>left</i> of the rating stars is quite small on Now Playing views <i>with artwork</i>, it's probably better to click/touch the space to the right (about 40px wide).<br><br>
Alternatively or additionally, you can replace the <i>Shuffle</i> and <i>Repeat</i> buttons on Now Playing views that display track ratings with <b>rating buttons</b> that will increase or decrease the track rating by half a star. This setting is not enabled by default and can be change here: <i>Settings > Screen > Dark Flat Skin</i>.
</p></details><br>

<details><summary>»<b>Why you shouldn't use the <i>default</i> applet installer to update or remove the Dark Flat Skin applet.</b>«</summary><br><p>
The default/jivelite applet installer (<i>Settings > Advanced > Applet Installer</i>) can only add, remove or change (applet) folders in the <i>user</i> applets folder.<br>But Dark Flat Skin requires renaming of files in and copying files to the <i>NowPlaying</i> and <i>Clock</i> applet folders in the <b>protected</b> <i>jive applets folder</i>.<br><br>
If you used the <i>jivelite</i> applet installer to remove or update the Dark Flat Skin applet, some files/folders wouldn't be updated, removed or restored to its original version. This might result in a jivelite reboot loop (see FAQ article) or the Now Playing or Clock applets giving you problems (see FAQ article).
<br><br>
Therefore, please <i>only</i> use the <i>jivelite</i> applet installer to <b>install</b> the Dark Flat Skin <b><ins>installer</ins></b> but <i>NEVER</i> to <b>update</b> or <b>remove</b> the Dark Flat Skin applet.<br><i>ALWAYS</i> use the skin's own uninstaller (<i>Settings > Advanced > Uninstall Dark Flat Skin</i>) to <b>remove</b> the Dark Flat Skin applet, either permanently or as part of the update process.
</p></details><br>

<details><summary>»<b>I've selected a different VU meter design but it still displays the old one.</b>«</summary><br><p>
Please note: on <b>piCorePlayer</b>, the VU meter you select for the <i>Dark Flat Skin</i> is also used by the <i>Dark Flat <b>Grid</b> Skin</i>. You can't set a different VU meter for the <i>Grid</i> skin.<br><br>

For guaranteed success:<br>

- <b>SqueezePlay</b>: restart SqueezePlay.<br>On <i>Windows</i> (and possibly <i>Linux</i>) selecting a different VU meter requires <i>admin privileges</i>. Please read the corresponding FAQ article below<br>

- <b>piCorePlayer</b>: use the <i>Quit</i> button to restart jivelite.<br>

- <b>SB Touch</b>: reboot your device.<br><br>

Works <i>sometimes</i>:<br>

- Go to <b>Settings > Screen > NowPlaying > NowPlaying views</b>.<br>

- Deselect the analog VU meter view.

- Exit the menu.

- Then reenter the menu and select the analog VU meter view again.
</p></details><br>

<details><summary>»<b><i>SQUEEZEPLAY</i> on <i>WINDOWS</i> and <i>LINUX</i></b>«</summary><br><p>
<b>WINDOWS</b>:<br>
<b>Installing</b> and <b>uninstalling</b> the skin and <b>changing the VU meter design</b> require <b>admin privileges</b> on Windows, i.e. you need to `run SqueezePlay as admin` to install, uninstall or change the VU meter design.<br><br>
The installer has to rename files in and copy files to the <i>NowPlaying</i> and <i>Clock</i> applet folders in the protected <i>jive applet folder</i>. And on Windows, creating symbolic links (to change the VU meter design) seems to require admin privileges too.<br><br>
<b>LINUX</b>:<br>
It probably depends on <i>where</i> you've installed SqueezePlay. The installer requires write permissions (755) to rename files in and copy files to the <i>NowPlaying</i> and <i>Clock</i> applet folders in the <i>jive applet folder</i>.<br>
If you install the skin using <i>sudo</i>, it will install the userpath skin files in the <i>root</i> user's home folder. And nobody wants to run SqueezePlay as root all the time.<br>
So either the installer can write to the <i>jive applet folder</i> or you install the applet (files) manually.
</p></details><br>

<details><summary>»<b><u>SB Touch</u>: <i>after a reboot</i> the device seems to fall back to the <i>WQVGAsmallSkin</i> skin. Selecting the <i>Dark Flat Skin doesn't stick</i>.</b>«</summary><br><p>
The SB Touch knows 3 different skins settings: <b>Touch</b> Skin, <b>Remote</b> Skin, and just <b>”Skin”</b>. The GUI menus will let you change the <b>Touch</b> and the <b>Remote</b> skin type but not the type <b>“Skin“</b> which resets to <i>WQVGAsmallSkin</i> after every reboot.<br>
However, it's easy to fix:<br>

- go to **Settings > Screen > Select skin > Touch Skin**<br>

- select <i>WQVGAsmallSkin</i><br>

- and then select <i>Dark Flat Skin</i> again.<br><br>

It's a trade-off: <i>Dark Flat Skin</i> is a stand-alone/separate applet that's easy to install/uninstall. But that causes quirks like this one. It only happens after a <i>reboot</i>. So decide for yourself if you think it's worth it.
</p></details><br>

<details><summary>»<b>I've manually deleted some files/folders on my device. Now it's stuck in a <b>jivelite reboot loop</b> (pCP, SB Touch) or falls back to a tiny screen skin.</b>«</summary><br><p>
If you have manually deleted the skin files/folders instead of using the uninstaller, jivelite will still try to load the (missing) Dark Flat Skin. You need to change the selected skin value in the <i>SelectSkin.lua</i> settings file to a skin that's still installed, e.g. JogglerSkin (pCP) or WQVGAsmallSkin (for SB Touch) and reboot your device.
</p></details><br>

<details><summary>»<b>I've used the <i>jivelite</i> applet installer to remove/update Dark Flat Skin and now the Now Playing screen is not working.</b>«</summary><br><p>
If you have SSH access to your device, you can easily remove remaining files/folders or restore important files to their original version:<br>

- Delete all folders starting with `DarkFlatSkin` in the <i>user</i> applets folder.
- If there are files ending in `_ORG` in the <i>NowPlaying</i> or <i>Clock</i> applet folders (in the <i>jivelite</i> applets folder): delete the modified versions with the same name (without the `_ORG`) and remove the `_ORG` from the original files.<br>

- Backup (pCP only) and restart your device.
</p></details><br>

<details><summary>»<b><u>piCorePlayer</u>: I've enabled the analog VU meter and spectrum visualizer NowPlaying views but when I toggle through the NowPlaying views, these two are missing.</b>«</summary><br><p>
The VU meter and spectrum visualizer are only displayed if the device running jivelite is also a local player (e.g. if you have SqueezeLite running on your pCP device).
</p></details><br>

<details><summary>»<b>The Applet Installer doesn't show me the latest applet version.</b>«</summary><br><p>
Provided that the latest version has been picked up by the repository and that your server and your device have internet access, it's probably a caching problem.<br>Usually one or a combination of the following helps: restart LMS, reload the Settings > Plugins page, reboot your device.
</p></details><br>

<br><br><br>

## Reporting a new issue

If you want to report a new issue, please fill out this [**issue report template**](https://github.com/AF-1/jivelite-darkflatskin/issues/new?template=bug_report.md&title=%5BISSUE%5D+).<br><br>

If you'd like me to make small changes to the skin, please test the new changes on your device/OS first and then create a pull request with the changes here.<br><br>
If you use this applet and like it, perhaps you could give it a :star: so that other users can discover it (in their News Feed). Thank you.
<br><br><br>

[^1]: Based on *JogglerSkin* (piCorePlayer, SqueezePlay) and *WQVGAsmallSkin* (SB Touch).
[^2]: I don't own a SB Touch device. So I can't troubleshoot issues of the SB Touch version beyond UI issues. For known issues on SB Touch devices, please see the FAQ.
[^3]: The screenshots might not correspond to the current UI in every detail.