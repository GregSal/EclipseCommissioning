DICOM_path = '\\dkphysicspv1\e$\Gregs_Work\Gregs_Data\Eclipse Commissioning Data\eMC V13.6 Commissioning Data\Eclipse Calculated Data\Golden Beam Model\High Accuracy Calculations for RDF\12MeV';
Beam_data=get_plan_list(DICOM_path);
Beam = Beam_data(7);
Offset = mean(Beam.insertsize);
DICOM_dose_file = Beam.dose_file;
isocentre = Beam.isocentre;
PDD_Data = Extract_PDD(DICOM_dose_file, isocentre, Offset);
Dose = PDD_Data.dose;
Depth = PDD_Data.depth;

%% Obtain dmax Dose, R100 and max dose values
% find d_max by interpolating to half mm spacing around max dose
MaxDose = max(Dose);
RenormalizedDose = Dose/MaxDose*100;
DoseIndex = RenormalizedDose > 97;
DoseRegion = Dose(DoseIndex);
DoseRange = Depth(DoseIndex);
MinDepth = min(DoseRange);
MaxDepth = max(DoseRange);
InterpDepth = MinDepth:0.05:MaxDepth;
InterpDose = interp1(DoseRange,DoseRegion,InterpDepth,'pchip');
PDD_analysis.dmax_Dose = max(InterpDose);
PDD_analysis.R100 = InterpDepth(InterpDose==dmax_Dose);

%% Find R50
%Redo-normalization with interpolated Dmax
RenormalizedDose = Dose/PDD_analysis.dmax_Dose*100;

%select data past buildup region
BuildDownIndex = Depth > PDD_analysis.R100;
DoseIndexLow = RenormalizedDose > 30;
DoseIndexHigh = RenormalizedDose < 70;
DoseIndex = BuildDownIndex & DoseIndexLow & DoseIndexHigh;
DoseRegion = RenormalizedDose(DoseIndex);
DoseRange = Depth(DoseIndex);
PDD_analysis.R50 = interp1(DoseRegion,DoseRange,50,'linear');

