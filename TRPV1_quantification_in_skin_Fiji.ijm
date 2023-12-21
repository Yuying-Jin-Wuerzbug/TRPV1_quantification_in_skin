run("Set Measurements...", "area mean min integrated add redirect=None decimal=3");
setOption("BlackBackground", true);

var acceptedNonBioFormatsFiles = "tif, png";

run("Bio-Formats Macro Extensions");

userChosenDirectory = getDirectory("Choose a Directory");
outputChoseDirectory = getDirectory("where to put");

processBioFormatFiles(userChosenDirectory);

function processBioFormatFiles(currentDirectory) {

	fileList = getFileList(currentDirectory);
	
	//for (file = 38; file < fileList.length; file++) {  //！！！一旦中断，可以修改file=0，如已经算了3个lif,就可以从file=3继续。

	for (file = 0; file < fileList.length; file++) {  //！！！一旦中断，可以修改file=0，如已经算了3个lif,就可以从file=3继续。
		
		Ext.isThisType(currentDirectory + fileList[file], supportedFileFormat);
		
		if (supportedFileFormat=="true" && !matches(acceptedNonBioFormatsFiles, ".*" + substring(fileList[file], lengthOf(fileList[file])-3) + ".*")) {   //巧妙应用substring()和Lengthof（）字符总长度，可以截取从右到左三位字符
			Ext.setId(currentDirectory + fileList[file]);
			Ext.getSeriesCount(seriesCount);
			//print(currentDirectory + fileList[file]);
			givennumber=1;
			for (series = 1; series <= seriesCount; series++) {
				if (matches(currentDirectory + fileList[file]+series, ".*lif.*")) {
					
					Ext.setSeries(series-1);
					Ext.getSeriesName(seriesName);
//					print(seriesName);
					if (matches(seriesName, ".*LVCC.*")) {
						run("Bio-Formats Importer", "open=[" + currentDirectory + fileList[file] + "] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"+series);
						runMyMacro();
					givennumber=givennumber+1;	
					}
			
				}
			

				else {
				run("Bio-Formats Importer", "open=[" + currentDirectory + fileList[file] + "] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"+series);
				//runMyMacro();
				}
				
			}
			
		} else if (matches(acceptedNonBioFormatsFiles, ".*" + substring(fileList[file], lengthOf(fileList[file])-3) + ".*")) {
			
			open(currentDirectory + fileList[file]);
			//runMyMacro();
			
		} else if (File.isDirectory(currentDirectory + fileList[file])) {
			
			//processBioFormatFiles(currentDirectory + fileList[file]);
			
		}
	}
}

/*
 * Your license if any
 */

function runMyMacro() {
	
	outputDirName = outputChoseDirectory + "Analysis";                  //outputDirName is plan to give the  "   " as a name to the new folder, path is in the same level with inputDir 
	outputDirPath = outputDirName + File.separator;         //outputDirPath is the path for analysed image to store, the path is under the level with inputDir
	File.makeDirectory(outputDirName);  
	outputDirName_Flow = outputChoseDirectory + "Analysis"+"/"+"Flow";
	outputDirPath_Flow = outputDirName_Flow + File.separator; 
	File.makeDirectory(outputDirName_Flow); 
	outputDirName_Roi = outputChoseDirectory + "Analysis"+"/"+"Roi_manager";
	outputDirPath_Roi = outputDirName_Roi + File.separator; 
	File.makeDirectory(outputDirName_Roi); 
	outputDirName_scatter = outputChoseDirectory + "Analysis"+"/"+"scatter";
	outputDirPath_scatter = outputDirName_scatter + File.separator; 
	File.makeDirectory(outputDirName_scatter); 
	
	originalImage = getTitle();
	sampleNumber = substring(originalImage, 0, lengthOf(originalImage)-31);
	sample_SeriesNumber =substring(originalImage, lengthOf(originalImage)-18, lengthOf(originalImage)-9);
	//print(sampleNumber,sample_SeriesNumber);
	//print("Original image = " + originalImage);
	PGP = "C1-MAX_" + originalImage;
	TRPV1 = "C3-MAX_" + originalImage;
	DAPI = "C2-MAX_" + originalImage;
	//!!! Z project in maxium intensity
	run("Z Project...", "projection=[Max Intensity]");
	//!!! split channels
	run("Split Channels"); 
	close(DAPI); 
	selectWindow(PGP);
	
	
	run("Duplicate...", "title=["+ PGP +"_copy]"); //copy the PGP-single channel named with "  .*_copy   "
	duplicate = getTitle();

	run("Trainable Weka Segmentation");
	wait(500);
	
	call("trainableSegmentation.Weka_Segmentation.loadClassifier", "C:\\Users\\JIN_Y\\Documents\\TRPV1 Macro\\classifier1_3.model");
	wait(100);
	call("trainableSegmentation.Weka_Segmentation.loadData", "C:\\Users\\JIN_Y\\Documents\\TRPV1 Macro\\data1_3.arff");

	wait(100);
	call("trainableSegmentation.Weka_Segmentation.getProbability");
	wait(1000);
	selectWindow("Probability maps");
	run("Duplicate...", "use");
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Analyze Particles...", "size=0.25-Infinity circularity=0.00-0.78 show=Masks display exclude clear add composite");

	close("Probability maps");
	close(duplicate);
	//close("class 1");
	close(originalImage);
	close("Trainable Weka Segmentation v3.3.2");
	
	roiCount = roiManager("count");
	ROI_Array=newArray();
	for (n = 0; n < roiCount; n++) {
		ROI_Array[n] = n;
	}
	//merge all items in roimanager
	roiManager("Select",ROI_Array);
	roiManager("Combine");
	//add new merged item and rename it
	Roi.setName("PGP_area");
	roiManager("Add");
	roiManager("Select",ROI_Array);
	roiManager("delete");
	run("Clear Results");
	
	
	selectWindow(TRPV1);
	roiManager("Select", "PGP_area"); 

	run("Find Maxima...", "prominence=200 output=[Point Selection]");
	run("Add Selection...");
	//get the value from first one of "Count"column of Result table
	selectWindow(TRPV1);
	roiManager("Select", "PGP_area"); 
	run("Find Maxima...", "prominence=200 output=Count");
	pointCount=getResult("Count", 0);
	run("Clear Results");
	
	
	save(outputDirPath_scatter + File.getName("Scatterplot_" + sampleNumber + "_"+sample_SeriesNumber) + ".png");
	roiManager("save", outputDirPath_Roi + File.getName(sampleNumber + sample_SeriesNumber) + ".zip");

	
	
	
	ObjectImages = newArray(PGP,TRPV1);
	name_Images=newArray("PGP","TRPV1");
	for (image = 0; image <= 1; image++) {
		
		roiManager("Deselect");
		selectWindow(ObjectImages[image]);
		roiManager("Select","PGP_area");
		run("Measure");
		save(outputDirPath_Flow + File.getName(name_Images[image] + sampleNumber + "_"+sample_SeriesNumber) + ".png");
   		//close(ObjectImages[image]);
	}
	
	size_PGP = getResult("Area", 0);
	size_TRPV1 = getResult("Area", 1);
	// this "clear" step is important, otherwise the result table will also be written in excel
	run("Clear Results");
	
	Name = sampleNumber ;
	series=sample_SeriesNumber;
	
	Table.set("Number", 0 , Name,"Results");  // "Results" is the name created for a sheet
	Table.set("Histo-number", 0 , "H"+substring(Name, 0,lengthOf(Name)-2)+"/"+substring(Name, lengthOf(Name)-2,lengthOf(Name)),"Results"); 
	Table.set("Label", 0 , givennumber,"Results"); 
	Table.set("series", 0 , series,"Results"); 
	Table.set("total_dots", 0 , pointCount , "Results");   
	Table.set("area_size(µm^2)", 0, size_PGP , "Results");
	//Table.set("dots_density", 0, dots_density , "Results");
	
	
	
	
	

    // ResultsToexcel plugin need to install
    run("Read and Write Excel", "no_count_column file=["+ outputDirPath +"analyze.xlsx] stack_results dataset_label=[Primary_data] ");
    
	run("Clear Results");
    close("Results");
    roiManager("reset");
    selectWindow("ROI Manager");
	close("*");
    
}
