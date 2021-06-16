///Three Channel  Complete Macro - Tim Monko 10/12/2017 updated considerably
// Most recent update 02/24/2020
// This macro is designed to take a composite 16-bit (3 color) tiff image and normalize, then threshold each channel. Now with extra colocalization goodies

runSingleChannel16bitConversion = 0; //for grayscale 16-bit (single channel) images. These need to be converted to a Composite stack to work with the code, set to 1 if this is what you need.
	//Use the Red channel for all SingleChannel purposes.
numchannels = 3; //use the number of 16-bit channels, if RGB set to 3

runThresholdCode = 1; //if 1, then run the accompanying code, else skip
useConvolutedBS = 1; //if 1, then will use convoluted background subtraction (BioVoxxel Toolbox)rather than the default parabaloid rolling boll subtraction
runExtras = 1; //this is specifically for fillholes and remove particles based on size
runColocCode = 0; //1 = run colocalization using Binary Feature Extractor, 0 = off

/////////////////////////////////
///THRESHOLDING CODE VARIABLES///
/////////////////////////////////

//CHANNEL 1 / RED / CYAN /GRAY == also for 16-bit gray single channels
doCh1 = 1; // 1 = will run this  channel, 0 = skip, will close the image
Ch1tograyscale = 0; // 1 = will not threshold image, instead just puts on grayscale LUT (for things such as WFA)
Ch1rbr = 0.1; // Rolling ball radius.  
	// For old Photoshop binning. At 10X, 0.01 for poor S/N. Up to 0.1 for good S/N and/or larger cells
	// For RGB usually 1 -5
	// For new FIJI binning. 0.1 for poor S/N and high cell density, up to 5 for good S/N and lower cell density
Ch1ConvBS = 10; // Pixel diameter of largest cells to be kept as signal, for example ROR cells are at most 10pxs in diameter
Ch1MaxProminence = 10; //For Find Maxima. Higher prominence values require a greater differential between maxima peaks and adjacent pixels. Essentially, 
Ch1threslow = 0.1; // lower threshold for this channel, this is a "percentage" of the maximum signal from normalization, which helps intuitively. ie 0.20 means that what is kept is all values 20% or higher
Ch1MedianRadius = 1.5; //
//Ch1watererosion = 10; // if a number that is not zero is put in convex, then this value is ignored. 10 = around normal watershed algorithm
//Ch1waterconvex = 0; // Useful for dividing cells (PH3 + EdU) 0.95 might be good for dividng cells, but this is potentially threshold dependent. Keep this number high or it won't watershed soma effectively for our purposes (morphology analysis would be different)

//CHANNEL 2 / GREEN / MAGENTA
doCh2 = 1;
Ch2tograyscale = 0;
Ch2rbr = 0.1; // 0.01ish for 16-bit, 10ish for 8-bit (at 10x)
Ch2ConvBS = 10; 
Ch2MaxProminence = 10; 
Ch2threslow = 0.10; 
Ch2MedianRadius = 1.5; 
//Ch2watererosion = 70;
//Ch2waterconvex = 0;

//CHANNEL 3 / BLUE / YELLOW
doCh3 = 1; 
Ch3tograyscale = 0; 
Ch3rbr = 3; 
Ch3threslow = 0.05;
Ch3ConvBS = 10; 
Ch3MaxProminence = 10; 
Ch3MedianRadius = 2;
//Ch3watererosion = 10; 
//Ch3waterconvex = 0.95; 

//////////////////////
///EXTRAS Variables///
//////////////////////

//Fills holes, especially useful for certain Abs like PH3 which will have some holes after thresholding. Does override the original thresholded in order to
fillholesCh1 = 0; //Binary
fillholesCh2 = 0; //Binary
fillholesCh3 = 0; //Binary

//To remove small particles - this way things don't be counted as overlapping if its a noise that made it through the threshold filter. For now this will be resaved with the original which may be undesirable for counting, but I like it
removeparticlesCh1 = 1; particlesizeCh1 = 10;
removeparticlesCh2 = 1; particlesizeCh2 = 10;
removeparticlesCh3 = 1; particlesizeCh3 = 10;

/////////////////////////////////////
/// COLOCALIZATION CODE VARIABLES ///
////////////////////////////////////

imageCropping = 1; // to be used for post combining the images to crop to ROIs and such 

//Which channels do you have? 1= run this channel for its accompanying colocalization, 0 = this channel isn't there so don't run it
haveCh1 = 1;
haveCh2 = 1;
haveCh3 = 1;
haveTriple = 1;

//Objects and Selectors. These should be relatively consistent for the marker that you are doing.
//OverlapXX = Percentages for the BFE overlap filter. Needs to be identified for every colocalization separately. To do so use Analyze Particles with %Area Output. Set the redirect in "Set Measurements". The Object image is analyzed, while the selector image is redirected against.
//Binary feature extractory is a BioVoxxel plugin that compares two images, checks for a percentage of overlap, and recombines the images with an output selecting only colocalized images

ObjectCh1Ch2 = "Ch1"; //format = "Color", i.e. "Red"
SelectorCh1Ch2 = "Ch2";
overlapCh1Ch2 = 30; //this is the BFE percentage. (see above)

ObjectCh1Ch3 = "Ch3";
SelectorCh1Ch3 = "Ch1";
overlapCh1Ch3 = 30;

ObjectCh2Ch3 = "Ch2";
SelectorCh2Ch3 = "Ch3";
overlapCh2Ch3 = 30;

ObjectTriple = "Ch2";
SelectorTriple = ObjectCh1Ch3 + "_On_" + SelectorCh1Ch3; //this is the only format that is slightly different. use the object/selector combo as such to call the properly title image. leave the "_On_" intact.
overlapTriple = 40;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
imageTitle=getTitle(); //returns a string with the image title, used later for saving 

close("\\Others"); // because of the false batch mode this will allow only the front image to remain to prevent cluttering 
setBatchMode("true");
roiManager("Add");
run("Select All");

if (runSingleChannel16bitConversion == 1) {
	run("Add Slice");
}

/// CODE FOR THRESHOLDING STARTS BELOW ///

if (runThresholdCode == 1) {
	run("Make Composite");
	run("Split Channels"); //separates the 3 channels to its own color image

	/// CHANNEL 1 / RED / CYAN

	if (doCh1 == 1 && Ch1tograyscale == 0) {
		selectWindow("C1-"+imageTitle); 
		rename("Ch1"); //useful to more reliably call on the image, especially in future macros (such as coloc macro)
		run("Grays");
		if (useConvolutedBS == 1) {
			run("Convoluted Background Subtraction", "convolution=Median radius=Ch1ConvBS");
		} else {
			run("Subtract Background...", "rolling=Ch1rbr sliding"); //Subtract background using slidiing parabaloid. radius =0.01 seems to be appropriate for all 16-bit counts (for Tim at least)
		}
//new code //
		run("Median...", "radius=Ch1MedianRadius");
		run("Find Maxima...", "prominence=Ch1MaxProminence output=[Segmented Particles]");
		selectWindow("Ch1");
// end new code// 
		run("Duplicate...", " "); //Duplicates image so that original is not blurred, this code will add a -1 to the title of the new image
		selectWindow("Ch1-1");  
		//run("Median...", "radius=2"); //Runs median blur of the image, uses pixel radius of 2, I think that radius looks ok
		//setBatchMode("false"); //This command will show a hidden image (as occurs in batch mode) allowing a bin to be drawn to get the max value
		waitForUser;
		List.setMeasurements; //saves measurements to a list
		//print(List.getList); // lists all measurements, useful for future Ref
		mxg = List.getValue("Max"); //pulls Max brightness value from List and saves as variable mxg (i.e. max green)
		close("Ch1-1"); //closes the duplicate

		selectWindow("Ch1"); 
		run("32-bit"); //convert from 16-bit to 32-bit (floating point scale). 
		run("Divide...", "value=mxg"); //Normalization - divides the image by the previously determined max (mxg)

		setAutoThreshold("Otsu dark"); //this command preferred over run("Threshold..."), because it uses Otsu's method 
		//run("Threshold..."); 
		if (Ch1threslow > 0) {
			setThreshold(Ch1threslow, 100); //using 32-bit float values gives a max of 3.4e38, but nothing should be above 4
		}
		setOption("BlackBackground", true);
		run("Convert to Mask");
		imageCalculator("AND create", "Ch1","Ch1 Segmented");
		close("Ch1 Segmented");
		close("Ch1");
		selectWindow("Result of Ch1");
		rename("Ch1");
		roiManager("Select", 0);
		run("Add Selection...");
		//setBatchMode("true");
		//run("Watershed"); //splits some cells with watershed algorithm, for now this has been replaced by the Watershed Irregular Features for use with dividing cells 
		//run("Watershed Irregular Features", "erosion=Ch1watererosion convexity_threshold=Ch1waterconvex separator_size=0-Infinity");
	} 
	if (doCh1 == 0 && numchannels > 2) {
		selectWindow("C1-"+imageTitle); 
		close("C1-"+imageTitle);
	}

	if (doCh1 == 1 && Ch1tograyscale == 1) {
		selectWindow("C1-"+imageTitle); 
		rename("Ch1");
		run("8-bit");
	}

/// CHANNEL 2 / GREEN / MAGENTA

	if (doCh2 == 1 && Ch2tograyscale == 0) {
		selectWindow("C2-"+imageTitle); 
		rename("Ch2"); //useful to more reliably call on the image, especially in future macros (such as coloc macro)
		run("Grays");
		if (useConvolutedBS == 1) {
			run("Convoluted Background Subtraction", "convolution=Median radius=Ch2ConvBS");
		} else {
			run("Subtract Background...", "rolling=Ch2rbr sliding"); //Subtract background using slidiing parabaloid. radius =0.01 seems to be appropriate for all 16-bit counts (for Tim at least)
		}
//new code //
		run("Median...", "radius=Ch2MedianRadius");
		run("Find Maxima...", "prominence=Ch2MaxProminence output=[Segmented Particles]");
		selectWindow("Ch2");
// end new code// 
		run("Duplicate...", " "); //Duplicates image so that original is not blurred, this code will add a -1 to the title of the new image
		selectWindow("Ch2-1");  
		//run("Median...", "radius=2"); //Runs median blur of the image, uses pixel radius of 2, I think that radius looks ok
		//setBatchMode("false"); //This command will show a hidden image (as occurs in batch mode) allowing a bin to be drawn to get the max value
		waitForUser;
		List.setMeasurements; //saves measurements to a list
		//print(List.getList); // lists all measurements, useful for future Ref
		mxg = List.getValue("Max"); //pulls Max brightness value from List and saves as variable mxg (i.e. max green)
		close("Ch2-1"); //closes the duplicate

		selectWindow("Ch2"); 
		run("32-bit"); //convert from 16-bit to 32-bit (floating point scale). 
		run("Divide...", "value=mxg"); //Normalization - divides the image by the previously determined max (mxg)

		setAutoThreshold("Otsu dark"); //this command preferred over run("Threshold..."), because it uses Otsu's method 
		//run("Threshold..."); 
		if (Ch2threslow > 0) {
			setThreshold(Ch2threslow, 100); //using 32-bit float values gives a max of 3.4e38, but nothing should be above 4
		}
		setOption("BlackBackground", true);
		run("Convert to Mask");
		imageCalculator("AND create", "Ch2","Ch2 Segmented");
		close("Ch2 Segmented");
		close("Ch2");
		selectWindow("Result of Ch2");
		rename("Ch2");
		roiManager("Select", 0);
		run("Add Selection...");
		//setBatchMode("true");
		//run("Watershed"); //splits some cells with watershed algorithm, for now this has been replaced by the Watershed Irregular Features for use with dividing cells 
		//run("Watershed Irregular Features", "erosion=Ch2watererosion convexity_threshold=Ch2waterconvex separator_size=0-Infinity");
	} 
	
	if (doCh2 == 0 && numchannels > 2) {
		selectWindow("C2-"+imageTitle); 
		close("C2-"+imageTitle);
	}

	if (doCh2 == 1 && Ch2tograyscale == 1) {
		selectWindow("C2-"+imageTitle); 
		rename("Ch2");
		run("8-bit");
	}


/// CHANNEL 3 / BLUE / YELLOW

	if (doCh3 == 1 && Ch3tograyscale == 0) {
		selectWindow("C3-"+imageTitle); 
		rename("Ch3"); //useful to more reliably call on the image, especially in future macros (such as coloc macro)
		run("Grays");
		if (useConvolutedBS == 1) {
			run("Convoluted Background Subtraction", "convolution=Median radius=Ch3ConvBS");
		} else {
			run("Subtract Background...", "rolling=Ch3rbr sliding"); //Subtract background using slidiing parabaloid. radius =0.01 seems to be appropriate for all 16-bit counts (for Tim at least)
		}
//new code //
		run("Median...", "radius=Ch3MedianRadius");
		run("Find Maxima...", "prominence=Ch3MaxProminence output=[Segmented Particles]");
		selectWindow("Ch3");
// end new code// 
		run("Duplicate...", " "); //Duplicates image so that original is not blurred, this code will add a -1 to the title of the new image
		selectWindow("Ch3-1");  
		//run("Median...", "radius=2"); //Runs median blur of the image, uses pixel radius of 2, I think that radius looks ok
		//setBatchMode("false"); //This command will show a hidden image (as occurs in batch mode) allowing a bin to be drawn to get the max value
		waitForUser;
		List.setMeasurements; //saves measurements to a list
		//print(List.getList); // lists all measurements, useful for future Ref
		mxg = List.getValue("Max"); //pulls Max brightness value from List and saves as variable mxg (i.e. max green)
		close("Ch3-1"); //closes the duplicate

		selectWindow("Ch3"); 
		run("32-bit"); //convert from 16-bit to 32-bit (floating point scale). 
		run("Divide...", "value=mxg"); //Normalization - divides the image by the previously determined max (mxg)

		setAutoThreshold("Otsu dark"); //this command preferred over run("Threshold..."), because it uses Otsu's method 
		//run("Threshold..."); 
		if (Ch3threslow > 0) {
			setThreshold(Ch3threslow, 100); //using 32-bit float values gives a max of 3.4e38, but nothing should be above 4
		}
		setOption("BlackBackground", true);
		run("Convert to Mask");
		imageCalculator("AND create", "Ch3","Ch3 Segmented");
		close("Ch3 Segmented");
		close("Ch3");
		selectWindow("Result of Ch3");
		rename("Ch3");
		roiManager("Select", 0);
		run("Add Selection...");
		//setBatchMode("true");
		//run("Watershed"); //splits some cells with watershed algorithm, for now this has been replaced by the Watershed Irregular Features for use with dividing cells 
		//run("Watershed Irregular Features", "erosion=Ch3watererosion convexity_threshold=Ch3waterconvex separator_size=0-Infinity");
	} 
	if (doCh3 == 0 && numchannels > 2) {
		selectWindow("C3-"+imageTitle); 
		close("C3-"+imageTitle);
	}

	if (doCh3 == 1 && Ch3tograyscale == 1) {
		selectWindow("C3-"+imageTitle); 
		rename("Ch3");
		run("8-bit");
	}


	if (doCh1 + doCh2 + doCh3 >= 2) {
		run("Images to Stack");
		run("8-bit");
	}
	if (runColocCode != 1 && runExtras != 1) {
		rename(imageTitle);
	}
}

///RUN EXTRAS CODE ///

if (runExtras == 1) {
	if (doCh1 + doCh2 + doCh3 >= 2) {
		run("Stack to Images");
	}

//The following chunk will a) fill holes if there are any (usually a few pixels in things like PH3) then b) remove small noise particles to make colocalizations not rely on too small of an roi
	if (doCh1 == 1 && Ch1tograyscale != 1) {
		selectWindow("Ch1");
		if (fillholesCh1 == 1) { run("Fill Holes", "slice"); } 
		if (removeparticlesCh1 == 1) { run("Particles4 ", "white show=Particles filter minimum=particlesizeCh1 maximum=9999999 redirect=None"); }
		//run("Duplicate...", " ");
	} 

	if (doCh2 == 1 && Ch2tograyscale != 1) {
		selectWindow("Ch2");
		if (fillholesCh2==1) { run("Fill Holes", "slice"); }
		if (removeparticlesCh2==1) { run("Particles4 ", "white show=Particles filter minimum=particlesizeCh2 maximum=9999999 redirect=None"); } // This takes out particles with an area less than 15 (background)
		//run("Duplicate...", " ");
	}

	if (doCh3==1 && Ch2tograyscale != 1) {
		selectWindow("Ch3");
		if (fillholesCh3== 1) { run("Fill Holes", "slice"); } 
		if (removeparticlesCh3 == 1) { run("Particles4 ", "white show=Particles filter minimum=particlesizeCh3 maximum=9999999 redirect=None"); }
		//run("Duplicate...", " ");
	}
		if (doCh1 + doCh2 + doCh3 >= 2) {
		run("Images to Stack"); 
	}
}

///COLOCALIZATION CODE STARTS BELOW #######################

if(runColocCode == 1 && runExtras != 1) {
	run("Invert LUT"); //
	run("Stack to Images");
} 
if(runColocCode ==1 && runExtras ==1) {
	run("Stack to Images");
}

if(runColocCode ==1) {
//The following chunks will do colocalization for only the appropriate slices to avoid errors. 
if (haveCh1==1 && haveCh2==1) {
	selectWindow(ObjectCh1Ch2);
	run("Duplicate...", " "); 
	rename("Object12");
	selectWindow(SelectorCh1Ch2);
	run("Duplicate...", " "); 
	rename("Selector12");
	run("Binary Feature Extractor", "objects=Object12 selector=Selector12 object_overlap=overlapCh1Ch2");
	rename(ObjectCh1Ch2 + "_On_" + SelectorCh1Ch2);
	close("Object12");
	close("Selector12");
}

if (haveCh1==1 && haveCh3==1) {
	selectWindow(ObjectCh1Ch3);
	run("Duplicate...", " "); 
	rename("Object13");
	selectWindow(SelectorCh1Ch3);
	run("Duplicate...", " "); 
	rename("Selector13");
	run("Binary Feature Extractor", "objects=Object13 selector=Selector13 object_overlap=overlapCh1Ch3");
	rename(ObjectCh1Ch3 + "_On_" + SelectorCh1Ch3);
	close("Object13");
	close("Selector13");
}

if (haveCh2==1 && haveCh3==1) {
	selectWindow(ObjectCh2Ch3);
	run("Duplicate...", " "); 
	rename("Object23");
	selectWindow(SelectorCh2Ch3);
	run("Duplicate...", " "); 
	rename("Selector23");
	run("Binary Feature Extractor", "objects=Object23 selector=Selector23 object_overlap=overlapCh2Ch3");
	rename(ObjectCh2Ch3 + "_On_" + SelectorCh2Ch3);
	close("Object23");
	close("Selector23");
}

if (haveTriple==1) {
	selectWindow(ObjectTriple);
	run("Duplicate...", " "); 
	rename("ObjectTriple");
	selectWindow(SelectorTriple);
	run("Duplicate...", " "); 
	rename("SelectorTriple");
	run("Binary Feature Extractor", "objects=ObjectTriple selector=SelectorTriple object_overlap=overlapTriple");
	rename("Triple");
	close("ObjectTriple");
	close("SelectorTriple");
}

//Close the duplicated images so the final stack is only up to 7 images 
if (haveCh1==1) { close("Ch1-1"); }
if (haveCh2==1) { close("Ch2-1"); }
if (haveCh3==1) { close("Ch3-1"); }

run("Images to Stack"); //Not sure why, but this does stack them all in the proper order - even after selecting them out of order 
}

rename('BLINDED_MUHAHAHAHAHA'); //This way the code can nicely end knowing if BFE has been run 
roiManager("Delete");
if (imageCropping==1) {
	waitForUser("Press OK When Finished", "(1) 'x' Crop and Clear outside selected ROI \n(2) 'g' Clear outside of drawn ROI - Slice \n(3) 'u' Clear outside of drawn ROI - Stack \n(4) '0' Clear inside drawn ROI");
}
