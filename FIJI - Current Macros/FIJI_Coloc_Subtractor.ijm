colocalization = 1; // the original colocalization code 
cellsubtractor = 1; // after colocalization, can use this to remove double positive cells from the original channel in order to 

///
//run("Slice Remover", "first=4 last=9 increment=1");
run("Stack to Images");

Object 	= newArray(	"Ch1",
					"Ch2",
					"Ch1",
					"Ch2",
					"Ch3",
					"Ch3",
					"Ch3",
					"Ch3"
					);
Selector= newArray(	"Ch2", 
					"Ch1",
					"Ch3",
					"Ch3",
					"Ch1",
					"Ch2",
					"Ch2_On_Ch1",
					"Ch1_On_Ch2"
					);
Overlap = 35

Primary = newArray("Ch1",
				   "Ch2",
				   "Ch1_On_Ch3"
				   );

Subtractor = newArray("Ch1_On_Ch2",
					  "Ch2_On_Ch1",
					  "Ch1_On_Ch2"
					  );

if (colocalization == 1) {
	for (i = 0; i<Object.length; i++) {
		selectWindow(Object[i]);
		run("Duplicate...", " "); 
		rename("Object");
		selectWindow(Selector[i]);
		run("Duplicate...", " "); 
		rename("Selector");
		run("Binary Feature Extractor", "objects=Object selector=Selector object_overlap=Overlap");
		rename(Object[i] + "_On_" + Selector[i]);
		close("Object");
		close("Selector");
	}
}

if (cellsubtractor == 1) {
	for (j = 0; j < Primary.length; j++) {
		imageCalculator("Subtract create", Primary[j], Subtractor[j]);
		rename(Primary[j] + "_Minus_" + Subtractor[j]);
		
	}
}
run("Images to Stack");
