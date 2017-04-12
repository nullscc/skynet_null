#!	/bin/python

import os
import sys
import codecs
import json
import xlrd

from optparse import OptionParser
json.encoder.FLOAT_REPR = lambda x: format(x, '.4f')



class XLSDoc:

    def __init__(self, input_path, output_path):
        self.sheets = []
        self.sheetPageName = []
        self.inputPath = input_path
        self.outputPath = output_path

    def readDoc(self, fileName, startRow, startCol, attributesRow, attributesTypeRow):
        doc = xlrd.open_workbook(self.inputPath + fileName)
        #print doc.nsheets

#        for i in range(doc.nsheets):
        sheet = Sheet(startRow, startCol, attributesRow, attributesTypeRow)
        sheetToAdd = doc.sheet_by_index(0)
        nameToAdd = sheetToAdd.name.lower()
            #nameToAdd = nameToAdd.split('_')[-1] 
            #if(isInVector(nameToAdd, self.sheetPageName) < 0):
            #    self.sheetPageName.append(nameToAdd)
        sheet.readSheet(sheetToAdd, fileName)
        self.sheets.append(sheet)

    def outPutToJSON(self):
        for sheet in self.sheets:
            sheet.toJson(self.outputPath + sheet.fileName)

class Sheet:

    def __init__(self, sr, sc, ar, atr):
        self.sheetName = ""
        self.attributes = []
        self.contents = []
        self.contentsType = []
        self.fileName = ""
        self.sheet_dict = {}
        self.row_dict = {}
        self.startRow = sr
        self.startCol = sc
        self.attributesRow = ar
        self.attributesTypeRow = atr

    def readSheet(self, sheetObj, _fileName):
        self.sheetName = sheetObj.name
        if (sheetObj.name.find("Sheet") > 0):
            self.fileName = self.sheetName + ".json"
        else:
            self.fileName = _fileName[0:_fileName.find('.')] + ".json"

        outCols =  0
        
        for col in range(self.startCol, sheetObj.ncols):
            try:
                if ("" != str(sheetObj.cell(self.attributesRow, col).value)):
                   outCols = outCols + 1
                   self.attributes.append(sheetObj.cell(self.attributesRow, col).value)
                   self.contentsType.append(sheetObj.cell(self.attributesTypeRow, col).value)
            except UnicodeEncodeError:
                print "Sheet name: ", self.sheetName, " row: ", self.attributesRow, " col: ", col+1
                #print(sheetObj.cell(self.attributesRow, col).value)
                #print(sheetObj.cell(self.attributesTypeRow, col).value)
                #print('----------')
        #print(outCols)
        
        for i in range(self.startRow, sheetObj.nrows):
            entity = {}
            null = True
            for j in range(0, outCols):
                try:
                    value = sheetObj.cell(i, self.startCol + j).value
                    if (value != ''):
                        null = False
                    rowType = self.contentsType[j]
                    key = self.attributes[j]

                    if rowType != "" and (key.find('#') == -1):
                        tr_value = self._convertValueByXlSType(self.contentsType[j], value)
                        entity[key] = tr_value
                except UnicodeEncodeError:
                    print "convert error,", self.fileName
                    print "sheet name : ",self.sheetName," row : ", i, " col : ", self.startCol + j + 1
                except:
                    print "sheet name : ",self.sheetName," row : ", i, " col : ", self.startCol + j + 1
                    #print sys.exc_info()[0]," : ",sys.exc_info()[1] 
            if not null:
                self.contents.append(entity)
 
    def toJson(self, outputPath):
        jsonFile = codecs.open(outputPath, 'w', 'utf-8')
        jsonFile.write("%s" % json.dumps(self.contents, ensure_ascii=False, indent=4))
        jsonFile.close()

    def _convertValue(self, value):
        if(type(value) == float and int(value) == value):
            return str(int(value))
        elif(type(value) != str and type(value) != unicode):
            return str(value)
        else:
            return value

    def _convertValueByXlSType(self, t_xlsType, value):
        
        xlsType = str(t_xlsType)
        if (xlsType == 'int'):
            if (value == ''):
                return 0
            else:
                return int(value)
        elif (xlsType == 'string' and value != ''):
            if ( type(value) == float ):
                if (value == int(value)):
                    value = int(value)
                    return str(value)
                else:
                    return value;
            else:
                return value;
        elif (xlsType == 'float' and value != ''):
            return float(value)
        else:
            return str(value)



if __name__ == '__main__':
    parser = OptionParser()

    parser.add_option("-i", "--input", dest="input_path",
                     default="../xls/",
                     help="read all .xls file from this path")
    parser.add_option("-o", "--output", dest="output_path",
                     default="../",
                     help="write all .json file to this path")
    options, args = parser.parse_args()
    

    fileNames = os.listdir(options.input_path)
    
    XLS = XLSDoc(options.input_path, options.output_path)
    for fileName in fileNames:
        #print(args)
        if (fileName == str(args[0])):
            XLS.readDoc(fileName, int(args[1]), int(args[2]), int(args[3]), int(args[4]))

        XLS.outPutToJSON()
