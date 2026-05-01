# Ethos-Lua
Collection of tools for use with FrSky Ethos

I use a FrSky X20S transmitter and have found the need for some widgets and tools which I am sharing here in case others find them of use. 

Many of the following will have been created with the help of AI. 

  
##   
## FS Status Widget

The FS have a blue light in them to indicate when they are active, however in any sort of bright light this becomes pretty much invisible. This widget therefore displays the status of the various FS. In the following example FS3 is active. 

<img width="287" height="122" alt="Screenshot 2025-10-01 194655" src="https://github.com/user-attachments/assets/802f727e-a214-4c4b-9ac1-240ff95fb485" />  


##  
## TouchOnOff Widget  

This provides a simple two-button On/Off touch widget for FrSky Ethos. 
It displays an ON touch button and an OFF touch button inside the widget area. Both brighten when touched.
The Widget title and button text can be changed in the Widget configuration dialog.
Touching ON outputs +100% (1024) at the lua source and touching OFF outputs -100% (-1024) at the lua source.
For more details see the comments in the code. 

As coded this widget can be used up to 10 times within a single model as 10 widgets are pre-registered, however if more are required then 
just change the MAX_WIDGETS value. The configuration advises which lua source is being used so you know which source to use in mixes, LS etc..

<img width="796" height="474" alt="image" src="https://github.com/user-attachments/assets/052c571d-b19b-49a2-a19f-fa2ce92fb8a1" />

###
### Configuration options
###

<img width="796" height="476" alt="image" src="https://github.com/user-attachments/assets/69429fa0-0bc9-408c-a408-50cca990a680" />  


##
## Battery Consumption Tracker

For those who fly motorised gliders, a LiPo may last multiple flights or even all day. However Ethos doesn't keep track of how much battery you use across multiple flights. The Battery Consumption widget is therefore designed to do this. 
It will track the consumption on the current flight (Flight) together with the total consumption across multiple flights on the same day (Total). On a new day both are automatically reset to zero. There is also a touch Reset icon to enable you to reset both to zero should you change battery part way through a days flying. 

<img width="255" height="111" alt="image" src="https://github.com/user-attachments/assets/591491c6-1b01-49ac-b610-f510fd663d76" />  

The sensor is selectable in the configuration so this could be used for other sensors too. Whether units are displayed on the title line or beside the values is also selectable, however on the title line may be preferable for large batteries with a small widget area. 

<img width="793" height="250" alt="image" src="https://github.com/user-attachments/assets/2b780faf-1e88-4f82-ad6a-991f0c05b3e1" />



##  
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


##
##
