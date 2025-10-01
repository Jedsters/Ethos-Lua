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
The current Ethos manual at the time of writing (1.6.3) details 2 means to to create the map image, the first is somewhat tricky and long while the second is much simpler and refers the user to the hobby4life website for a tool which largely automates the process. Unfortunately the latter has since gone offline. 

This tool is therefore a replacement for the hobby4life website largely automating the process. 

The tool is nothing more than some html which the user can store on their device and execute using their preferred browser when required (not all browsers have been tested). 
When executed the tool shows a satellite map with a GPS Coordinate Selector box at the top left. This allows the user to choose which type of map they want to download from Satellite (ESRI World Imagery), OpenStreetMap (Standard) or Topographic (OpenTopoMap). These were selected in preference to e.g. Google or Bing in that there is no API Key required which makes the tool immediately usable without having to register etc..

To locate the area to download the user would typically select the OSM and navigate to the required area before perhaps changing to one of the other maps, the former having the advantage of having place names marked on it. 
When the create selection box is selected a box of 800 x 480 pixels is displayed which can then be dragged around the screen as needed. It can also be resized although this perhaps isn't desirable since the X20 requires a map of 800 x 480 pixels. 

Once the selected area is correctly identified Get GPS Coordinates can then be selected which will show the latitude and longitude of the area. Copy Formatted Coordinates can then be selected to copy the coordinates which can then be saved along with the map image. 

The following shows the initial display and final display (which is certainly not an area suitable for model flying!)

<img width="1816" height="1027" alt="Screenshot 2025-10-01 182215" src="https://github.com/user-attachments/assets/93a43303-2b53-4d22-ba52-0bd81df68b00" />



<img width="1918" height="1040" alt="Screenshot 2025-10-01 182446" src="https://github.com/user-attachments/assets/cbddcc95-133c-4bc6-b827-1d2ec5a6c030" />
