<?xml version="1.0" encoding="UTF-8"?>
<!--
    Document   : merge-plugin-files.xsl
    Created on : 22 de outubro de 2019, 12:40
    Author     : Luciano Barcellos
    Description:
        Merge plugin.xml files.
-->

<xsl:stylesheet version="1.0"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exsl="http://exslt.org/common" extension-element-prefixes="exsl">

    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="/plugin/comment()[
        starts-with(., ' ## ') or
        starts-with(preceding-sibling::node()[2]/self::comment(), ' ## ')
    ]"/>

    <xsl:template match="/plugin/text()[
        position()=last() or
        starts-with(following-sibling::node()[1]/self::comment(), ' ## ') or
        starts-with(preceding-sibling::node()[1]/self::comment(), ' ## ') or
        starts-with(preceding-sibling::node()[3]/self::comment(), ' ## ')
    ]"/>

    <xsl:template match="/plugin/*[
        starts-with(preceding-sibling::node()[4]/self::comment(), ' ## ')
    ]"/>

    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="/plugin/*" mode="final">
        <xsl:text>&#xa;&#xa;    </xsl:text>
        <xsl:comment><xsl:value-of select="concat(' ## ', @id, ' ')"/></xsl:comment>
        <xsl:copy-of select="preceding-sibling::node()[position() &lt; 4]"/>
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="final"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="node()|@*" mode="final">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="final"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="/plugin">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
            <xsl:apply-templates select="document('plugin.xml')/plugin/*" mode="final"/>
            <xsl:text>&#xa;</xsl:text>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
