import { jsPDF } from "jspdf";
import { PatientProfile } from "./demoData";

export function generateThyroidReportPDF(patient: PatientProfile): jsPDF {
  const doc = new jsPDF({
    orientation: "portrait",
    unit: "mm",
    format: "a4"
  });

  const primaryTeal = "#0D9494";
  const navyHeader = "#051F38";
  const darkInk = "#12171F";
  const lightBg = "#F5F7FA";

  // --- HEADER BANNER ---
  doc.setFillColor(5, 31, 56); // #051F38 Deep Navy
  doc.rect(0, 0, 210, 32, "F");

  // Logo Mark accent box
  doc.setFillColor(13, 148, 148); // #0D9494 Teal
  doc.rect(14, 10, 10, 10, "F");
  
  doc.setFont("helvetica", "bold");
  doc.setFontSize(16);
  doc.setTextColor(255, 255, 255);
  doc.text("THYROCARE", 28, 17);

  doc.setFontSize(9);
  doc.setFont("helvetica", "normal");
  doc.setTextColor(212, 245, 237); // Mint accent
  doc.text("CLINICAL THYROID INTELLIGENCE REPORT", 28, 22);

  doc.setFontSize(8);
  doc.setTextColor(200, 210, 225);
  doc.text(`Generated: ${new Date().toLocaleDateString("en-US", { month: "long", day: "numeric", year: "numeric" })}`, 145, 17);
  doc.text("CONFIDENTIAL MEDICAL RECORD", 145, 22);

  // --- PATIENT METADATA BOX ---
  let y = 40;
  doc.setFillColor(245, 247, 250);
  doc.setDrawColor(220, 227, 234);
  doc.roundedRect(14, y, 182, 26, 2, 2, "FD");

  doc.setFont("helvetica", "bold");
  doc.setFontSize(12);
  doc.setTextColor(18, 23, 31);
  doc.text(patient.name.toUpperCase(), 18, y + 8);

  doc.setFont("helvetica", "normal");
  doc.setFontSize(9);
  doc.setTextColor(70, 85, 106);
  doc.text(`MRN: #${patient.mrn || "THY-84920"}  |  Age: ${patient.age}  |  Sex: ${patient.sex}  |  Condition: ${patient.condition}`, 18, y + 15);
  doc.text(`Primary Clinician: Dr. Jane Smith  |  Relationship: ${patient.relationship || "Patient"}`, 18, y + 21);

  // --- SUMMARY CARDS ---
  y += 32;
  doc.setFont("helvetica", "bold");
  doc.setFontSize(10);
  doc.setTextColor(5, 31, 56);
  doc.text("CURRENT THYROID HORMONAL STATUS", 14, y);

  y += 4;
  // Card 1: TSH
  doc.setFillColor(240, 253, 250);
  doc.setDrawColor(13, 148, 148);
  doc.roundedRect(14, y, 56, 22, 2, 2, "FD");
  doc.setFontSize(8);
  doc.setTextColor(13, 148, 148);
  doc.text("LATEST TSH", 18, y + 6);
  doc.setFontSize(14);
  doc.setFont("helvetica", "bold");
  doc.setTextColor(5, 31, 56);
  doc.text(`${patient.latestTSH} mIU/L`, 18, y + 14);
  doc.setFontSize(7);
  doc.setFont("helvetica", "normal");
  doc.text("Ref: 0.40 - 4.50 mIU/L", 18, y + 19);

  // Card 2: Trend
  doc.setFillColor(248, 250, 252);
  doc.setDrawColor(220, 227, 234);
  doc.roundedRect(77, y, 56, 22, 2, 2, "FD");
  doc.setFontSize(8);
  doc.setTextColor(70, 85, 106);
  doc.text("LONGITUDINAL TREND", 81, y + 6);
  doc.setFontSize(12);
  doc.setFont("helvetica", "bold");
  doc.setTextColor(18, 23, 31);
  doc.text(patient.trend, 81, y + 14);
  doc.setFontSize(7);
  doc.setFont("helvetica", "normal");
  doc.text(`Last Assayed: ${patient.lastLabDate}`, 81, y + 19);

  // Card 3: Dosage
  doc.setFillColor(248, 250, 252);
  doc.setDrawColor(220, 227, 234);
  doc.roundedRect(140, y, 56, 22, 2, 2, "FD");
  doc.setFontSize(8);
  doc.setTextColor(70, 85, 106);
  doc.text("ACTIVE REGIMEN", 144, y + 6);
  doc.setFontSize(10);
  doc.setFont("helvetica", "bold");
  doc.setTextColor(18, 23, 31);
  const activeMed = patient.medications[0];
  doc.text(activeMed ? `${activeMed.name} ${activeMed.dose}` : "Levothyroxine 100mcg", 144, y + 13);
  doc.setFontSize(7);
  doc.setFont("helvetica", "normal");
  doc.text(activeMed ? activeMed.frequency : "Daily on empty stomach", 144, y + 19);

  // --- CLINICAL ASSISTED SUMMARY ---
  y += 28;
  doc.setFont("helvetica", "bold");
  doc.setFontSize(10);
  doc.setTextColor(5, 31, 56);
  doc.text("CLINICAL SUMMARY & OBSERVATIONS", 14, y);

  y += 4;
  doc.setFillColor(255, 255, 255);
  doc.setDrawColor(220, 227, 234);
  doc.roundedRect(14, y, 182, 24, 2, 2, "FD");

  doc.setFont("helvetica", "normal");
  doc.setFontSize(8.5);
  doc.setTextColor(40, 50, 65);
  const summaryText = patient.notes?.[0]?.text || 
    `Patient ${patient.name} shows a latest TSH level of ${patient.latestTSH} mIU/L (${patient.trend.toLowerCase()}). High dietary calcium intake and meal timing buffer advisories have been highlighted. Synthetic levothyroxine therapy is active with stable tolerability. Routine follow-up scheduled for ${patient.nextVisit}.`;
  
  const splitSummary = doc.splitTextToSize(summaryText, 174);
  doc.text(splitSummary, 18, y + 7);

  // --- LABORATORY HISTORY TABLE ---
  y += 30;
  doc.setFont("helvetica", "bold");
  doc.setFontSize(10);
  doc.setTextColor(5, 31, 56);
  doc.text("ASSAYED LABORATORY HISTORY", 14, y);

  y += 4;
  // Table Header
  doc.setFillColor(235, 240, 245);
  doc.rect(14, y, 182, 7, "F");
  doc.setFontSize(8);
  doc.setFont("helvetica", "bold");
  doc.setTextColor(70, 85, 106);
  doc.text("DATE", 18, y + 5);
  doc.text("TSH (mIU/L)", 58, y + 5);
  doc.text("FREE T4 (ng/dL)", 98, y + 5);
  doc.text("FREE T3 (pg/mL)", 138, y + 5);
  doc.text("LABORATORY", 168, y + 5);

  y += 7;
  doc.setFont("helvetica", "normal");
  doc.setFontSize(8);
  doc.setTextColor(18, 23, 31);

  patient.labs.forEach((lab, idx) => {
    if (idx % 2 === 1) {
      doc.setFillColor(248, 250, 252);
      doc.rect(14, y, 182, 6.5, "F");
    }
    doc.text(lab.date, 18, y + 4.5);
    doc.setFont("helvetica", "bold");
    doc.text(`${lab.tsh}`, 58, y + 4.5);
    doc.setFont("helvetica", "normal");
    doc.text(`${lab.ft4}`, 98, y + 4.5);
    doc.text(`${lab.ft3}`, 138, y + 4.5);
    doc.text(lab.labName, 168, y + 4.5);

    y += 6.5;
  });

  // --- MEDICATION REGIMEN TABLE ---
  y += 6;
  doc.setFont("helvetica", "bold");
  doc.setFontSize(10);
  doc.setTextColor(5, 31, 56);
  doc.text("ACTIVE MEDICATIONS & DOSING SCHEDULE", 14, y);

  y += 4;
  doc.setFillColor(235, 240, 245);
  doc.rect(14, y, 182, 7, "F");
  doc.setFontSize(8);
  doc.setFont("helvetica", "bold");
  doc.setTextColor(70, 85, 106);
  doc.text("MEDICATION", 18, y + 5);
  doc.text("DOSE", 78, y + 5);
  doc.text("FREQUENCY", 118, y + 5);
  doc.text("TIMING BUFFER", 158, y + 5);

  y += 7;
  doc.setFont("helvetica", "normal");
  doc.setFontSize(8);

  patient.medications.forEach((med, idx) => {
    if (idx % 2 === 1) {
      doc.setFillColor(248, 250, 252);
      doc.rect(14, y, 182, 6.5, "F");
    }
    doc.text(med.name, 18, y + 4.5);
    doc.text(med.dose, 78, y + 4.5);
    doc.text(med.frequency, 118, y + 4.5);
    doc.text(med.timing, 158, y + 4.5);
    y += 6.5;
  });

  // --- DISCLAIMER & FOOTER ---
  y = 272;
  doc.setDrawColor(220, 227, 234);
  doc.line(14, y, 196, y);

  doc.setFont("helvetica", "normal");
  doc.setFontSize(7);
  doc.setTextColor(110, 125, 145);
  doc.text("ThyroCare Clinical Intelligence System — Confidential Patient Document. Generated via verified authorization.", 14, y + 4);
  doc.text("Disclaimer: ThyroCare assists clinicians and patients in organizing thyroid metrics. It does not replace clinical evaluation.", 14, y + 8);
  doc.text("Page 1 of 1", 185, y + 4);

  return doc;
}

export function downloadThyroidReportPDF(patient: PatientProfile) {
  const pdf = generateThyroidReportPDF(patient);
  const formattedDate = new Date().toISOString().split("T")[0];
  const safeName = patient.name.replace(/[^a-zA-Z0-9]/g, "_");
  const filename = `ThyroCare_Thyroid_Report_${safeName}_${formattedDate}.pdf`;
  pdf.save(filename);
}
