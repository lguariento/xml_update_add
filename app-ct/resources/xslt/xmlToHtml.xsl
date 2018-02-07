<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ct="www.curioustravellers.ac.uk/ns/namespace" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="tei" version="3.0"><!-- <xsl:strip-space elements="*"/>-->
    <xsl:param name="ref"/>
 
    <!-- substring-after-last custom function -->
    <xsl:function name="ct:substring-after-last" as="xs:string">
        <xsl:param name="value" as="xs:string?"/>
        <xsl:param name="separator" as="xs:string"/>        
        <xsl:choose>
            <xsl:when test="contains($value, $separator)">
                <xsl:value-of select="ct:substring-after-last(substring-after($value, $separator), $separator)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$value"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <!-- end of substring-after-last function -->
    
    <xsl:template match="/">
        <div class="page-header">
            <h3 align="center">
                <xsl:value-of select="//tei:fileDesc/tei:titleStmt/tei:title"/>
                    <br/>

            </h3>
        </div>
        <div class="regest">
            <div class="panel panel-default">
                <div class="panel-heading">
                    <h3 class="panel-title">
                        <h4 align="center">Metadata</h4>
                    </h3>
                </div>
                <div class="panel-body">
                    <table class="table table-striped">
                        <tbody>
                            <tr>
                                <th>
                                    <abbr>Title</abbr>
                                </th>
                                <td>
                                    
                                    <xsl:variable name="sentOn" select="//tei:correspAction[@type = 'sent']/tei:date/@when"/>
                                        <xsl:variable name="year" select="substring-before($sentOn, '-')"/>
                                        <xsl:variable name="month" select="substring($sentOn, 6, 2)"/>
                                        <xsl:variable name="day" select="ct:substring-after-last($sentOn, '-')"/>
                                    Letter from <xsl:value-of select="//tei:correspAction[@type = 'sent']/tei:persName"/>
                                    to <xsl:value-of select="//tei:correspAction[@type = 'received']/tei:persName"/>
                                    sent on <xsl:value-of select="$day"/>/<xsl:value-of select="$month"/>/<xsl:value-of select="$year"/>
                                    <br/>
                                </td>
                            </tr>
                            <xsl:if test="//tei:msIdentifier">
                                <tr>
                                    <th>
                                        <abbr>Identifier</abbr>
                                    </th>
                                    <td>
                                        <xsl:value-of select="//tei:msIdentifier/tei:repository"/> (<xsl:value-of select="//tei:msIdentifier/tei:settlement"/>),
                                        item <xsl:value-of select="//tei:msIdentifier/tei:idno"/>, folio <xsl:value-of select="//tei:msContents/tei:ab/tei:locus"/>
                                    </td>
                                </tr>
                            </xsl:if>
                            <tr>
                                <th>
                                    <abbr>Enclosed?</abbr>
                                </th>
                                <td>
                            <xsl:value-of select="if (//tei:div/@type = 'enclosed') then 'Yes' else 'No'"/>
                                </td>
                            </tr>
                            <tr>
                                <th>
                                    <abbr>Additons</abbr>
                                </th>
                                <td>
                                    <xsl:apply-templates select="//tei:physDesc/tei:additions"/>
                                </td>
                            </tr>

                            
                        </tbody>
                    </table>
                    <!--                    <div class="panel-footer">
                        <p style="text-align:center;">
                            <a id="link_to_source"/>
                        </p>-->
                    <!--</div>-->
                </div>
            </div>
        </div>
        <div class="panel panel-default">
            <div class="panel-heading">
                <h3 class="panel-title">
                    <h4 align="center">
                        Transcription
                    </h4>
                </h3>
            </div>
            <div class="panel-body" id="transcribed_text">
                <div class="row">
                    
                    <div class="col-md-12">
                        <p>
                            <xsl:choose>
                                <xsl:when test="//tei:div[@type='text']">
                                    <xsl:apply-templates select="//tei:div[@type='text']"/>
                                </xsl:when>
<!--                                <xsl:when test="//tei:div[@type='transcript']">
                                    <xsl:apply-templates select="//tei:div[@type='transcript']"/>
                                </xsl:when>-->
                                <xsl:otherwise>
                                    <xsl:apply-templates select="//tei:body"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </p>
                    </div>
                </div>
            </div>
            <div class="panel-body" id="footnotes">
                <div class="row">
                    
                    <div class="col-md-12">
                        <hr/>
                        <h6>Notes</h6>
                        <xsl:apply-templates select=".//tei:note" mode="footnote"/>
                    </div>
                </div>
            </div>
            <script type="text/javascript">
                // creates a link to the xml version of the current document available via eXist-db's REST-API
                var params={};
                window.location.search
                .replace(/[?&amp;]+([^=&amp;]+)=([^&amp;]*)/gi, function(str,key,value) {
                params[key] = value;
                }
                );
                var path = window.location.origin+window.location.pathname;
                var replaced = path.replace("exist/apps/", "exist/rest/db/apps/");
                current_html = window.location.pathname.substring(window.location.pathname.lastIndexOf("/") + 1)
                var source_document = replaced.replace("pages/"+current_html, "data/letters/"+params['document']);
                console.log(source_document)
                $( "#link_to_source" ).attr('href',source_document);
                $( "#link_to_source" ).text(source_document);
            </script>
        </div>
    </xsl:template>

    <!-- People -->
    <xsl:template match="tei:persName">
        <xsl:choose>
        <xsl:when test="(contains(@ref, ' '))">
            <xsl:apply-templates/>
        </xsl:when>
            <xsl:otherwise>
                <a href="http://localhost:8080/exist/apps/app-ct/pages/hits.html?searchkey={@ref}">
                    <xsl:apply-templates/>
                </a>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Places -->
    <xsl:template match="tei:placeName">
        <a href="http://localhost:8080/exist/apps/app-ct/places/{@ref}">
            <xsl:apply-templates/>
        </a>
    </xsl:template>

    <!-- Highlighting -->
    <xsl:template match="tei:hi[@rend = 'underline']" mode="#default deletion addition">
        <span class="underline">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="tei:hi[@rend = 'italic']" mode="#default deletion addition">
        <span class="italic">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="tei:hi[@rend = 'superscript']" mode="#default deletion addition">
        <sup>
            <xsl:apply-templates/>
        </sup>
    </xsl:template>
    
    <!-- abbreviations -->
        
        
    <xsl:template match="tei:choice">
        <xsl:for-each select="tei:abbr">   
            <xsl:apply-templates select="."/>
        </xsl:for-each>
        <xsl:for-each select="tei:expan">
            <xsl:text>[</xsl:text>
            <xsl:apply-templates select="."/>
            <xsl:text>]</xsl:text>
        </xsl:for-each>
    </xsl:template>
    
    <!-- footnotes (see http://www.microhowto.info/howto/create_a_list_of_numbered_footnotes_using_xslt.html) -->
    
   
    <xsl:template match="tei:note">
        <a>
            <xsl:attribute name="name">
                <xsl:text>footnoteref</xsl:text>
                <xsl:number level="any" count="tei:note" format="1"/>
            </xsl:attribute>
            <xsl:attribute name="href">
                <xsl:text>#footnote</xsl:text>
                <xsl:number level="any" count="tei:note" format="1"/>
            </xsl:attribute>
            <sup>
                <xsl:number level="any" count="tei:note" format="1"/>
            </sup>
        </a>
    </xsl:template>
       
    <xsl:template match="tei:note" mode="footnote">
        <br>
            <a>
                <xsl:attribute name="name">
                    <xsl:text>footnote</xsl:text>
                    <xsl:number level="any" count="tei:note" format="1"/>
                </xsl:attribute>
                <xsl:attribute name="href">
                    <xsl:text>#footnoteref</xsl:text>
                    <xsl:number level="any" count="tei:note" format="1"/>
                </xsl:attribute>
                <xsl:number level="any" count="tei:note" format="1"/>
                
            </a>
            <xsl:text> </xsl:text>
            <xsl:apply-templates/> <i>
                <xsl:value-of select="if (//tei:note/@type = 'editorial') then ' [Editorial note]' else ' [Authorial note]'"/>
            </i>
        </br>
    </xsl:template>
    
    <!-- opener    -->
    <xsl:template match="tei:opener">
        <p class="opener">
            <xsl:apply-templates/>
        </p>
    </xsl:template><!-- salute -->
    <xsl:template match="tei:salute">

            <xsl:apply-templates/>
        
    </xsl:template>
    
    <!-- closer -->
    <xsl:template match="tei:closer">
        <p class="closer">
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    
    <!-- stamp -->
    <xsl:template match="tei:stamp">
        <p class="well well-sm">
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    
    <!-- addrLine -->
    <xsl:template match="tei:addrLine">
        <p class="addrLine">
            <i>
                <xsl:apply-templates/>
            </i>
        </p>
    </xsl:template>
    
    <!--dateline-->
    <xsl:template match="tei:dateline">
        <p align="right">
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    
    <!-- resp -->
    <xsl:template match="tei:respStmt/tei:resp">
        <xsl:apply-templates/> 
    </xsl:template>
    <xsl:template match="tei:respStmt/tei:name">
        <xsl:for-each select=".">
            <li>
                <xsl:apply-templates/>
            </li>
        </xsl:for-each>
    </xsl:template><!-- reference strings   -->
    <xsl:template match="tei:rs[@ref or @key]">
        <i>
            <xsl:element name="a">
                <xsl:attribute name="class">reference</xsl:attribute>
                <xsl:attribute name="data-type">
                    <xsl:value-of select="concat('list', data(@type), '.xml')"/>
                </xsl:attribute>
                <xsl:attribute name="data-key">
                    <xsl:value-of select="substring-after(data(@ref), '#')"/>
                    <xsl:value-of select="@key"/>
                </xsl:attribute>
                <xsl:value-of select="."/>
            </xsl:element>
        </i>
    </xsl:template><!-- additions -->
    <xsl:template match="tei:add">
        <xsl:element name="span">
            <xsl:attribute name="style">
                <xsl:text>color:blue;</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="title">
                <xsl:choose>
                    <xsl:when test="@place='margin'">
                        <xsl:text>zeitgenössische Ergänzung am Rand </xsl:text>(<xsl:value-of select="./@place"/>).
                    </xsl:when>
                    <xsl:when test="@place='above'">
                        <xsl:text>Text added </xsl:text>
                        <xsl:value-of select="./@place"/>
                    </xsl:when>
                    <xsl:when test="@place='below'">
                        <xsl:text>Text added </xsl:text>(<xsl:value-of select="./@place"/>)
                    </xsl:when>
                    <xsl:when test="@place='inline'">
                        <xsl:text>Text added </xsl:text>(<xsl:value-of select="./@place"/>)
                    </xsl:when>
                    <xsl:when test="@place='top'">
                        <xsl:text>Text added to the </xsl:text>(<xsl:value-of select="./@place"/>)
                    </xsl:when>
                    <xsl:when test="@place='bottom'">
                        <xsl:text>Text added to the </xsl:text>(<xsl:value-of select="./@place"/>)
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>Text added somewhere</xsl:text>(<xsl:value-of select="./@place"/>)
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:text/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template><!-- Book -->
    <xsl:template match="tei:bibl">
        <xsl:element name="i">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template><!-- Seitenzahlen -->
    <xsl:template match="tei:pb">
        <xsl:element name="div">
            <xsl:attribute name="style">
                <xsl:text>text-align:right;</xsl:text>
            </xsl:attribute>
            <xsl:text>[Bl.</xsl:text>
            <xsl:value-of select="@n"/>
            <xsl:text>]</xsl:text>
        </xsl:element>
        <xsl:element name="hr"/>
    </xsl:template><!-- Table -->
    <xsl:template match="tei:table">
        <xsl:element name="table">
            <xsl:choose>
                <xsl:when test="@style='letter'">
                    <xsl:attribute name="class">
                        <xsl:text>table</xsl:text>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="class">
                        <xsl:text>table table-bordered table-striped table-condensed table-hover</xsl:text>
                    </xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:element name="tbody">
                <xsl:apply-templates/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:row">
        <xsl:element name="tr">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:cell">
        <xsl:element name="td">
            <xsl:choose>
                <xsl:when test="@style='left'">
                    <xsl:attribute name="style">
                        <xsl:text>text-align:left;</xsl:text>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="@style='right'">
                        <xsl:attribute name="style">
                            <xsl:text>text-align:right;</xsl:text>
                    </xsl:attribute>
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template><!-- Überschriften -->
    <xsl:template match="tei:head">
        <xsl:element name="h3">
            <xsl:element name="a">
                <xsl:attribute name="id">
                    <xsl:text>text_</xsl:text>
                    <xsl:value-of select="."/>
                </xsl:attribute>
                <xsl:attribute name="href">
                    <xsl:text>#nav_</xsl:text>
                    <xsl:value-of select="."/>
                </xsl:attribute>
                <xsl:apply-templates/>
            </xsl:element>
        </xsl:element>
    </xsl:template><!--  Quotes / Zitate -->
    <xsl:template match="tei:q">
        <xsl:element name="i">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template><!-- Zeilenumbürche   -->
    <xsl:template match="tei:lb">
        <br/>
    </xsl:template><!-- Absätze    -->
    <xsl:template match="tei:p">
        <xsl:element name="p">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template><!-- Durchstreichungen -->
    <xsl:template match="tei:del">
        <xsl:element name="strike">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:w">
        <xsl:value-of select="./text()"/>
    </xsl:template>
</xsl:stylesheet>