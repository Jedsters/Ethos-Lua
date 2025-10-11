# Ethos-Lua
Collection of tools for use with FrSky Ethos

I use a FrSky X20S transmitter and have found the need for some widgets and tools which I am sharing here in case others find them of use. 

Many of the following will have been created with the help of AI. 

## FS Status Widget

The FS have a blue light in them to indicate when they are active, however in any sort of bright light this becomes pretty much invisible. This widget therefore displays the status of the various FS. In the following example FS3 is active. 

<img width="287" height="122" alt="Screenshot 2025-10-01 194655" src="https://github.com/user-attachments/assets/802f727e-a214-4c4b-9ac1-240ff95fb485" />


## Map downloader tool

Ethos comes with a GPS Map widget which enables maps to be displayed on the transmitter screen with the current location identified on the map.
The configuration requires a map image to be specified together with the latitude and longitude of the of left / right and top / bottom of the map. 
The current Ethos manual at the time of writing (1.6.3) references https://www.rcgroups.com/forums/showpost.php?p=47392275&postcount=8854 which details 2 methods to create the map image, the first is somewhat tricky and long while the second is much simpler and refers the user to the hobby4life website for a tool which largely automates the process. Unfortunately the latter has since gone offline. 

This tool is therefore a partial replacement for the hobby4life website replacing the tricky part of the process. The remaining part can be performed with existing tools. 

The tool is some html which the user can store on their device and execute using their preferred browser when required (not all browsers have been tested). 
When executed the tool shows a satellite map with a GPS Coordinate Selector box at the top left. This allows the user to choose which type of map they want to download from: Satellite (ESRI World Imagery); OpenStreetMap (Standard) or Topographic (OpenTopoMap). These were selected in preference to e.g. Google or Bing in that there is no API Key required which makes the tool immediately usable without having to register etc..

To locate the area to download the user would typically select the OSM and navigate to the required area before perhaps changing to one of the other maps, the former having the advantage of having place names marked on it. 
When the create selection box is selected, a box of 800 x 480 pixels is displayed, unless one of the other resolutions is selected, which can then be dragged around the screen as needed. It can also be resized although this perhaps isn't desirable since the supplied resolutions are those for the X20, X14 and X18. 

Once the selected area is correctly identified Get GPS Coordinates can then be selected which will show the latitude and longitude of the area. Copy Formatted Coordinates can then be selected to copy the coordinates which can then be saved. The map area selected can then be saved using normal Windows screenshot copying inside the green rectangle. Note that although Windows screenshot doesn't give an option to save in .bmp format, if you select Edit in Paint that then does allow the image to be saved in .bpm format. The area can doubtless be saved in other OS using similar tools, or indeed alternative tools shuch as Greenshot on Windows which allows easier capture to the pixel.  The .bmp can then be transcoded to the correct format for Ethos using the Ethos suite Image manager and then transferred to the transmitter and referenced in the Map widget configuration and the copied coordinates also entered into the configuration.

The following shows the initial display and final display 

 <img width="1918" height="1037" alt="Screenshot 2025-10-02 174216" src="https://github.com/user-attachments/assets/673eafcc-bdc6-48da-8b79-b20c28a94fac" />



<img width="1911" height="1038" alt="Screenshot 2025-10-02 174253" src="https://github.com/user-attachments/assets/42c64117-86f8-4598-a9fb-44d6d3117980" />

