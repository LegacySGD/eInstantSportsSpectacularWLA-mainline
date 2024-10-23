<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[

var debugFeed = [];
var wheelsDescribed  = {
	emotiWheel: ['C','F','A','A','B','L','A','E','E','C','F','B','D','D','E','L','A','B','B','D','C','B','C','C','D','L','E','F','F','A'],
	mutiplierWheel: [3,2,3,1,3,2,3,1,3,2],
	featureWheel: ['.','+','.','X','.','|','.','+','.','X'],
    winWheel:[5,13,12,11,10,9,8]
};

function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc) {
	var scenario = getScenario(jsonContext);
	var tranMap = parseTranslations(translations);
	var prizeMap = parsePrizes(prizeNamesDesc, prizeValues);

	return doFormatJson(scenario, tranMap, prizeMap);
}

function scenarioConvertor(scenario) {
	var scenarioDelimits = scenario.split("|");	
	var wheelDetails = scenarioDelimits[0].split(':');
	var iWDetails = [], bonusDetails = [];

	if (scenarioDelimits[1] !== undefined){
		iWDetails = scenarioDelimits[1].split(',');
	}

	if(scenarioDelimits[2] !== undefined){
		bonusDetails =  scenarioDelimits[2].split(',').slice(1);
	}

	return {
		wheelDetails: wheelDetails,
		iWDetails: iWDetails,
		bonusDetails: bonusDetails
	}
}

function getWinEmotiNums(spinEmotiPosition, spinFeature, totalWinMap, mutiplierMap){
    var totalWinNums = spinFeature === 'X' ? 5 : 3;
    var len = wheelsDescribed.emotiWheel.length;

    if (spinEmotiPosition<0) {
        var totalWinDistance = wheelsDescribed.emotiWheel.slice(spinEmotiPosition+len, len);
        totalWinDistance = totalWinDistance.concat(wheelsDescribed.emotiWheel.slice(0, totalWinNums + spinEmotiPosition));
    }
    else {
        if (spinEmotiPosition + totalWinNums > len) {
            var totalWinDistance = wheelsDescribed.emotiWheel.slice(spinEmotiPosition, len);
            totalWinDistance = totalWinDistance.concat(wheelsDescribed.emotiWheel.slice(0, spinEmotiPosition + totalWinNums - len));
        }
        else {
            var totalWinDistance = wheelsDescribed.emotiWheel.slice(spinEmotiPosition, spinEmotiPosition + totalWinNums);
        }
    }

    var winMap = { 'L': 0,'A': 0,'B': 0,'C': 0,'D': 0,'E': 0,'F': 0 };

    totalWinDistance.forEach(function(value){ winMap[value]++; });

    var mutiplier = 0;

    for (var key in mutiplierMap) {        
        var element = mutiplierMap[key];

        if (element > 0) {
            mutiplier = Number(key);
            break;
        }            
    }

    if (mutiplier !== 0) {
        for (var key in totalWinMap) {
            var element = winMap[key];

            if (element > 0) {
                totalWinMap[key] += winMap[key]*mutiplier;
            }   
        }
    }
    else {
        for (var key in totalWinMap) {
            var element = winMap[key];

            if (element > 0) {
                totalWinMap[key] += winMap[key];
            }  
        }
    }

    return winMap;
}

function getWinMutiplierNums(spinMutiplier) {
    var winMap = { '1': 0,'2': 0,'3': 0 };
    var mutiplier = wheelsDescribed.mutiplierWheel[spinMutiplier-1];

    winMap[mutiplier]++;

    return winMap;
}

function doFormatJson(scenario, tranMap, prizeMap) {
	var result = scenarioConvertor(scenario);
	var emotiWheelLabels = [tranMap.silverBonus,tranMap.purple,tranMap.pink,tranMap.red,tranMap.yellow,tranMap.green,tranMap.blue];
    var emotiWheelWins = ['L','A','B','C','D','E','F'];
    var mutiplierLables = ['X1','X2','X3'];
    var featureLables = ['X','+','|'];
    var featureTranMap = [tranMap.expand, tranMap.extraSpin, tranMap.instantWin];
    var totalWinMap = { 'L': 0,'A': 0,'B': 0,'C': 0,'D': 0,'E': 0,'F': 0 };
	var r = [];
    var winBonus = false;
	
	for (var i = 0; i < result.wheelDetails.length; i++) {
		r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

        var currWinBonus = false;
        
        r.push('<tr>');
        r.push('<td colspan="9" style="font-weight: 600;padding-top:50px" >' + tranMap.spin + ' ' + (i + 1) + '</td>');
        r.push('</tr>');

        //for emoti wheel
		
        r.push('<tr>');
		r.push('<td class="tablehead" colspan="2">' + tranMap.emotiWheel + '</td>');

        for (var j = 0; j < emotiWheelLabels.length; j++) {
            r.push('<td class="tablehead">' + emotiWheelLabels[j] + '</td>');
        }

		r.push('</tr>');

        var spinResult = result.wheelDetails[i].split(',');
        var spinEmotiPosition = spinResult[0];	
        var spinMutiplier = spinResult[1];
        var spinFeature = spinResult[2];
        var featureDetails = wheelsDescribed.featureWheel[spinFeature-1];
        var mutiplierMap = getWinMutiplierNums(spinMutiplier);
        var winMap = getWinEmotiNums(spinEmotiPosition-1,featureDetails,totalWinMap,mutiplierMap);

        r.push('<tr>');
		r.push('<td colspan="2">' + tranMap.collected + '</td>');

        for (var j = 0; j < emotiWheelWins.length; j++) {
            r.push('<td>');

            if (winMap[emotiWheelWins[j]] > 0) {
                r.push(winMap[emotiWheelWins[j]]);
            }

            r.push('</td>');
        }

        r.push('</tr>');

        //for mutiplier wheel

        r.push('<tr>');
		r.push('<td class="tablehead" colspan="2">' + tranMap.mutiplierWheel + '</td>');

        for (var j = 0; j < mutiplierLables.length; j++) {
            r.push('<td class="tablehead">' + mutiplierLables[j] + '</td>');
        }

        r.push('</tr>');
        r.push('<tr>');
		r.push('<td colspan="2">' + tranMap.collected + '</td>');

        for (var j = 0; j < mutiplierLables.length; j++) {
            r.push('<td>');

            if (mutiplierMap[mutiplierLables[j].slice(1)] > 0) {
                r.push(mutiplierMap[mutiplierLables[j].slice(1)]);
            }

            r.push('</td>');
        }

        r.push('</tr>');

        //for feature wheel

        r.push('<tr>');
		r.push('<td class="tablehead" colspan="2">' + tranMap.featureWheel + '</td>');

        for (var j = 0; j < featureTranMap.length; j++) {
            r.push('<td class="tablehead">' + featureTranMap[j] + '</td>');
        }

        r.push('</tr>');
        r.push('<tr>');
		r.push('<td colspan="2">' + tranMap.collected + '</td>');

        for (var j = 0; j < featureLables.length; j++) {
            r.push('<td>');

            if (featureDetails === featureLables[j]) {
                r.push(1);
            }

            r.push('</td>');
        }

        r.push('</tr>');
        r.push('<tr>');
		r.push('<td colspan="2">' + tranMap.prizes + '</td>');

        for (var j = 0; j < featureLables.length; j++) {
            r.push('<td>');
            
            if (featureDetails === '|' && featureDetails === featureLables[j]) {
                var iwPrize = result.iWDetails.shift().trim();

                if (iwPrize) {
                    r.push(prizeMap[iwPrize]);
                }
            }

            r.push('</td>');
        }

        r.push('</tr>');
        r.push('<tr>');
        r.push('<td colspan="9">' + tranMap.summary + '</td>');
        r.push('</tr>');
        r.push('<tr>');
		r.push('<td class="tablehead" colspan="2">' + tranMap.emoticons + '</td>');

        for (var j = 0; j < emotiWheelLabels.length; j++) {
            r.push('<td class="tablehead">' + emotiWheelLabels[j] + '</td>');
        }

        r.push('</tr>');
        r.push('<tr>');
		r.push('<td colspan="2">' + tranMap.cumulative + '</td>');

        var k = 0;

        for (var key in totalWinMap) {
            var element = totalWinMap[key];

            r.push('<td>' + element +' / '+ wheelsDescribed.winWheel[k] + '</td>');

            k++;
        }

        r.push('</tr>');
        r.push('<tr>');
		r.push('<td colspan="2">' + tranMap.prizes + '</td>');

        var m = 0;

        for (var key in totalWinMap) {
            var element = totalWinMap[key];

            if (key !== 'L') {
                if (element === wheelsDescribed.winWheel[m]) {
                    r.push('<td>' + prizeMap[key] + '</td>');
                }
                else {
                    r.push('<td>' + '</td>');
                }
            }
            else {
                r.push('<td>' + '</td>');

                if (!winBonus && element === wheelsDescribed.winWheel[m]) {
                    winBonus = true;
                    currWinBonus = true;
                }
            }   

            m++;
        }

        r.push('</tr>');

        if (currWinBonus) {
            r.push('<tr>');
            r.push('<td class="tablehead" colspan="2">' + tranMap.bonusGame + '</td>');

            if (result.bonusDetails.length > 7) {
                for (var n = 0; n < 7; n++) {
                    r.push('<td>' + tranMap.bonusTurn + ' ' + (n + 1) + '</td>');
                }

                r.push('</tr>');
                r.push('<tr>');
                r.push('<td colspan="2">' + tranMap.collected + '</td>');

                for (var n = 0; n < 7; n++) {
                    r.push('<td>');

                    var lNumber = 0;
                    var element = result.bonusDetails[n];

                    element.split('').forEach(function(value){
                        if(value === 'L'){
                            lNumber++;
                        }
                    });

                    if(lNumber !== 0){
                        r.push(lNumber);
                    }

                    r.push('</td>');
                }

                r.push('</tr>');                
                r.push('<tr>');
                r.push('<td colspan="2">' + tranMap.prizes + '</td>');

                for (var n = 0; n < 7; n++) {
                    r.push('<td>' + '</td>');
                }

                r.push('</tr>');
                r.push('<tr>');
                r.push('<td colspan="2">' + '</td>');

                for (var n = 7; n < result.bonusDetails.length; n++) {
                    r.push('<td>' + tranMap.bonusTurn + ' ' + (n + 1) + '</td>');
                }

                r.push('</tr>');
                r.push('<tr>');
                r.push('<td colspan="2">' + '</td>');

                var totalNumber = 0;

                for (var n = 7; n < result.bonusDetails.length; n++) {
                    r.push('<td>');

                    var lNumber = 0;                   
                    var element = result.bonusDetails[n];

                    element.split('').forEach(function(value){
                        if (value === 'L') {
                            lNumber++;

                            if (n === result.bonusDetails.length - 1) {
                                totalNumber = lNumber;
                            }
                        }
                    });

                    r.push(lNumber);
                    r.push('</td>');
                }

                r.push('</tr>');
                r.push('<tr>');
                r.push('<td colspan="2">' + '</td>');

                for (var n = 7; n < result.bonusDetails.length; n++) {
                    r.push('<td>');

                    if (totalNumber >= 4) {
                        if (n === result.bonusDetails.length-1) {
                            r.push(prizeMap['L'+totalNumber]);
                        }
                    }

                    r.push('</td>');
                }

                r.push('</tr>');
            }
            else {
                for (var n = 0; n < result.bonusDetails.length; n++) {
                    r.push('<td>' + tranMap.bonusTurn + ' ' + (n + 1) + '</td>');
                }

                r.push('</tr>');
                r.push('<tr>');
                r.push('<td colspan="2">' + tranMap.collected + '</td>');
                
                var totalNumber = 0;

                for (var n = 0; n < result.bonusDetails.length; n++) {
                    r.push('<td>');
                
                    var lNumber = 0;
                    var element = result.bonusDetails[n];

                    element.split('').forEach(function(value) {
                        if (value === 'L') {
                            lNumber++;

                            if (n === result.bonusDetails.length - 1) {
                                totalNumber = lNumber;
                            }
                        }
                    });

                    if (lNumber !== 0) {
                        r.push(lNumber);
                    }

                    r.push('</td>');
                }

                r.push('</tr>');
                r.push('<tr>');
                r.push('<td colspan="2">' + tranMap.prizes + '</td>');

                for (var n = 0; n < result.bonusDetails.length; n++) {
                    r.push('<td>');

                    if (totalNumber >= 4) {
                        if (n === result.bonusDetails.length-1) {
                            r.push(prizeMap['L'+totalNumber]);
                        }
                    }

                    r.push('</td>');
                }

                r.push('</tr>');
            }
        }

		r.push('</table>');
	}
	
	return r.join('');
}

function getScenario(jsonContext) {
	var jsObj = JSON.parse(jsonContext);
	var scenario = jsObj.scenario;
	scenario = scenario.replace(/\0/g, '');
	return scenario;
}

function parsePrizes(prizeNamesDesc, prizeValues) {
	var prizeNames = (prizeNamesDesc.substring(1)).split(',');
	var convertedPrizeValues = (prizeValues.substring(1)).split('|');
	var map = [];
	for (var idx = 0; idx < prizeNames.length; idx++) {
		map[prizeNames[idx]] = convertedPrizeValues[idx];
	}
	return map;
}

function parseTranslations(translationNodeSet) {
	var map = [];
	var list = translationNodeSet.item(0).getChildNodes();
	for (var idx = 1; idx < list.getLength(); idx++) {
		var childNode = list.item(idx);
		if (childNode.name == "phrase") {
			map[childNode.getAttribute("key")] = childNode.getAttribute("value");
		}
	}
	return map;
}

// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
// Output: A string of the specific prize structure for the wagered price point
function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
{
	var pricePointList = pricePoints.split(",");
	var prizeStructStrings = prizeStructures.split("|");


	for(var i = 0; i < pricePoints.length; ++i)
	{
		if(wageredPricePoint == pricePointList[i])
		{
			return prizeStructStrings[i];
		}
	}

	return "";
}
////////////////////////////////////////////////////////////////////////////////////////
function registerDebugText(debugText)
{
	debugFeed.push(debugText);
}
/////////////////////////////////////////////////////////////////////////////////////////
function getTranslationByName(keyName, translationNodeSet)
{
	var index = 1;
	while(index < translationNodeSet.item(0).getChildNodes().getLength())
	{
		var childNode = translationNodeSet.item(0).getChildNodes().item(index);
		
		if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
		{
			registerDebugText("Child Node: " + childNode.name);
			return childNode.getAttribute("value");
		}
		
		index += 1;
	}
}


// Grab Wager Type
// @param jsonContext String JSON results to parse and display.
// @param translation Set of Translations for the game.
function getType(jsonContext, translations)
{
	// Parse json and retrieve wagerType string.
	var jsObj = JSON.parse(jsonContext);
	var wagerType = jsObj.wagerType;
	
	return parseTranslations(translations)[wagerType];
}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="SignedData/Data/Outcome/ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
