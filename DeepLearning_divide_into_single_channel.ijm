run("Set Measurements...", "area mean min integrated add redirect=None decimal=3");
setOption("BlackBackground", true);

var acceptedNonBioFormatsFiles = "tif, png";

run("Bio-Formats Macro Extensions");

userChosenDirectory = getDirectory("Choose a Directory");
outputChoseDirectory = getDirectory("where to put");

processBioFormatFiles(userChosenDirectory);

function processBioFormatFiles(currentDirectory) {

	fileList = getFileList(currentDirectory);
	


	for (file = 0; file < fileList.length; file++) {  
		
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
						
					}
			givennumber=givennumber+1;	
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
	originalImage = getTitle();
	sampleNumber = substring(originalImage, 0, lengthOf(originalImage)-31);
	sample_SeriesNumber =substring(originalImage, lengthOf(originalImage)-18, lengthOf(originalImage)-9);
	outputDirName = outputChoseDirectory + sampleNumber;                  //outputDirName is plan to give the  "   " as a name to the new folder, path is in the same level with inputDir 
	outputDirPath = outputDirName + File.separator;         //outputDirPath is the path for analysed image to store, the path is under the level with inputDir
	File.makeDirectory(outputDirName);  
	outputDirName_Flow_TRPV1 = outputChoseDirectory +sampleNumber + "/" + "TRPV1";
	outputDirPath_Flow_TRPV1 = outputDirName_Flow_TRPV1 + File.separator; 
	File.makeDirectory(outputDirName_Flow_TRPV1); 
	outputDirName_Flow_PGP = outputChoseDirectory +sampleNumber + "/" + "PGP";
	outputDirPath_Flow_PGP = outputDirName_Flow_PGP + File.separator; 
	File.makeDirectory(outputDirName_Flow_PGP); 
	outputDirName_Flow_PrePGP = outputChoseDirectory +sampleNumber + "/" + "PGP_pred";
	outputDirPath_Flow_PrePGP = outputDirName_Flow_PrePGP + File.separator; 
	File.makeDirectory(outputDirName_Flow_PrePGP); 
	outputDirPath_Flow= newArray(outputDirPath_Flow_PGP,outputDirPath_Flow_TRPV1);
	
	
	//print(sampleNumber,sample_SeriesNumber);
	//print("Original image = " + originalImage);
	PGP = "C1-MAX_" + originalImage;
	TRPV1 = "C3-MAX_" + originalImage;
	DAPI = "C2-MAX_" + originalImage;
	//!!! Z project in maxium intensity
	run("Z Project...", "projection=[Max Intensity]");
	//!!! split channels
	run("Split Channels"); 

	ObjectImages = newArray(PGP,TRPV1);
	name_Images=newArray("PGP","TRPV1");

	for (image = 0; image <= 1; image++) {

		selectWindow(ObjectImages[image]);
		save(outputDirPath_Flow[image] + File.getName(sampleNumber + "_" +sample_SeriesNumber) + ".tif");
   		//close(ObjectImages[image]);
	}
	close("*");
    
}
