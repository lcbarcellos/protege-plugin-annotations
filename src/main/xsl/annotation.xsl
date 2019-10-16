<?xml version="1.0" encoding="UTF-8"?>
<!--
    Document   : annotation.xsl
    Created on : 8 de outubro de 2019, 12:40
    Author     : luciano
    Description:
        Purpose of transformation follows.
-->

<xsl:stylesheet version="1.0"
                xmlns="http://www.w3.org/2001/XMLSchema"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exsl="http://exslt.org/common" extension-element-prefixes="exsl">
    <xsl:output method="text"/>

    <xsl:param name="package-name" select="''"/>

    <xsl:template match="/">
        <xsl:value-of select="concat('package ', $package-name, ';')"/>
        <xsl:value-of select="concat('import ', $package-name, '.source.Attribute;')"/>
        <xsl:value-of select="concat('import ', $package-name, '.source.Element;')"/>
        <xsl:value-of select="concat('import ', $package-name, '.source.ExtensionPoint;')"/>
        <xsl:text>import java.lang.annotation.ElementType;</xsl:text>
        <xsl:text>import java.lang.annotation.Retention;</xsl:text>
        <xsl:text>import java.lang.annotation.RetentionPolicy;</xsl:text>
        <xsl:text>import java.lang.annotation.Target;</xsl:text>
        <xsl:text>&#10;&#10;</xsl:text>

        <xsl:apply-templates select="xsd:schema/xsd:element[@name='extension']"/>
    </xsl:template>

    <xsl:template match="xsd:element[@name='extension']">
        <xsl:variable name="template">
            <xsl:apply-templates select="." mode="build-template"/>
        </xsl:variable>
        <xsl:text>/*&#10;</xsl:text>
        <xsl:apply-templates select="exsl:node-set($template)" mode="dump"/>
        <xsl:text>*/&#10;</xsl:text>
        <xsl:apply-templates select="exsl:node-set($template)" mode="annotation"/>
        <xsl:apply-templates select="exsl:node-set($template)" mode="typedef"/>
    </xsl:template>

    <xsl:template match="xsd:element" mode="build-template">
        <xsl:param name="minOccurs" select="1"/>
        <xsl:param name="maxOccurs" select="1"/>
        <xsl:element name="{@name}">
            <xsl:attribute name="x-min-occurs">
                <xsl:value-of select="$minOccurs"/>
            </xsl:attribute>
            <xsl:attribute name="x-max-occurs">
                <xsl:value-of select="$maxOccurs"/>
            </xsl:attribute>
            <xsl:attribute name="x-name">
                <xsl:value-of select="/xsd:schema/xsd:annotation/xsd:appInfo/xsd:meta.schema/@id"/>
            </xsl:attribute>
            <xsl:if test="@name='extension'">
                <xsl:attribute name="x-based-on">
                    <xsl:for-each select="
                            /xsd:schema
                                /xsd:element[@name='class']
                                    /xsd:complexType
                                        /xsd:attribute[@name='value']
                                            /xsd:annotation
                                                /xsd:appInfo
                                                    /xsd:meta.attribute/@basedOn
                        ">
                        <xsl:value-of select="translate(., ':', '')"/>
                    </xsl:for-each>
                </xsl:attribute>
            </xsl:if>
            <xsl:for-each select="xsd:complexType/xsd:attribute">
                <xsl:choose>
                    <xsl:when test="../../@name='extension' and @name='point'">
                        <xsl:attribute name="c-point">
                            <xsl:value-of select="/xsd:schema/xsd:annotation/xsd:appInfo/xsd:meta.schema/@plugin"/>
                            <xsl:text>.</xsl:text>
                            <xsl:value-of select="/xsd:schema/xsd:annotation/xsd:appInfo/xsd:meta.schema/@id"/>
                        </xsl:attribute>
                    </xsl:when>
                    <xsl:when test="../../@name='class' and @name='value'">
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="{@name}">
                            <xsl:value-of select="concat(@type)"/>
                        </xsl:attribute>
                        <xsl:for-each select="@use">
                            <xsl:attribute name="x-use">
                                <xsl:value-of select="."/>
                            </xsl:attribute>
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>

            </xsl:for-each>
            <xsl:for-each select="xsd:complexType/xsd:sequence/xsd:element">
                <xsl:apply-templates select="/xsd:schema/xsd:element[@name = current()/@ref]" mode="build-template">
                    <xsl:with-param name="minOccurs">
                        <xsl:choose>
                            <xsl:when test="@minOccurs != ''">
                                <xsl:value-of select="@minOccurs"/>
                            </xsl:when>
                            <xsl:otherwise>1</xsl:otherwise>
                        </xsl:choose>
                    </xsl:with-param>
                    <xsl:with-param name="maxOccurs">
                        <xsl:choose>
                            <xsl:when test="@maxOccurs != ''">
                                <xsl:value-of select="@maxOccurs"/>
                            </xsl:when>
                            <xsl:otherwise>1</xsl:otherwise>
                        </xsl:choose>
                    </xsl:with-param>
                </xsl:apply-templates>
            </xsl:for-each>
        </xsl:element>
    </xsl:template>

    <xsl:template match="*" mode="dump">
        <xsl:param name="indent" select="'&#10;'"/>

        <xsl:value-of select="$indent"/>
        <xsl:text>&lt;</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:for-each select="@*">
            <xsl:text> </xsl:text>
            <xsl:value-of select="name()"/>
            <xsl:text>="</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>"</xsl:text>
        </xsl:for-each>
        <xsl:choose>
            <xsl:when test="count(*|text()) &gt; 0">
                <xsl:text>&gt;</xsl:text>
                <xsl:apply-templates select="*" mode="dump">
                    <xsl:with-param name="indent" select="concat($indent, '  ')"/>
                </xsl:apply-templates>
                <xsl:if test="normalize-space(.) != '' and count(*) = 0">
                    <xsl:value-of select="normalize-space(.)"/>
                </xsl:if>
                <xsl:value-of select="$indent"/>
                <xsl:text>&lt;/</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text>&gt;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>/&gt;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*" mode="dump-path">
        <xsl:if test="position() &gt; 1">
            <xsl:text>/</xsl:text>
        </xsl:if>
        <xsl:value-of select="name()"/>
    </xsl:template>

    <xsl:template match="*" mode="annotation">
        <xsl:text>@ExtensionPoint(&#10;</xsl:text>
        <xsl:text>superClass=</xsl:text>
        <xsl:value-of select="@x-based-on"/>
        <xsl:text>.class, &#10;xmlStructure={</xsl:text>
        <xsl:apply-templates select=".|.//*" mode="annotation-item"/>
        <xsl:text>})</xsl:text>
    </xsl:template>

    <xsl:template match="*" mode="annotation-item">
        <xsl:if test="position() &gt; 1">
            <xsl:text>,&#10;</xsl:text>
        </xsl:if>
        <xsl:text>@Element(</xsl:text>
        <xsl:text>path="</xsl:text>
        <xsl:apply-templates select="ancestor-or-self::*" mode="dump-path"/>
        <xsl:text>"</xsl:text>
        <xsl:for-each select="@value">
            <xsl:text>, fieldName="</xsl:text>
            <xsl:value-of select="name(..)"/>
            <xsl:text>"</xsl:text>
        </xsl:for-each>
        <xsl:for-each select="@*[not(starts-with(name(), 'x-'))]">
            <xsl:choose>
                <xsl:when test="position() = 1">
                    <xsl:text>, attributes={</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>, </xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>@Attribute(name="</xsl:text>
            <xsl:choose>
                <xsl:when test="starts-with(name(), 'c-')">
                    <xsl:value-of select="substring(name(), 3)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="name()"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>", value="</xsl:text>
            <xsl:choose>
                <xsl:when test="starts-with(name(), 'c-')">
                    <xsl:value-of select="."/>
                </xsl:when>
                <xsl:when test="name() = 'value'">
                    <xsl:text>@</xsl:text>
                    <xsl:value-of select="name(..)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>@</xsl:text>
                    <xsl:value-of select="name()"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>")</xsl:text>
            <xsl:if test="position() = last()">
                <xsl:text>}</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text>)</xsl:text>
    </xsl:template>

    <xsl:template match="extension" mode="typedef">
        <xsl:text>@Target(ElementType.TYPE)</xsl:text>
        <xsl:text>@Retention(RetentionPolicy.SOURCE)</xsl:text>
        <xsl:text>public @interface </xsl:text>
        <xsl:value-of select="@x-name"/>
        <xsl:text> {&#10;</xsl:text>
        <xsl:text>String value() default "";</xsl:text>
        <xsl:text>}</xsl:text>
    </xsl:template>

    <xsl:template match="xsd:element" mode="old">
        <xsl:text>{ </xsl:text>
        <xsl:if test="@name='extension'">
            <xsl:text>"info": {</xsl:text>
            <xsl:for-each select="/xsd:schema/xsd:annotation/xsd:appInfo/xsd:meta.schema/@*">
                <xsl:text>"</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text>": "</xsl:text>
                <xsl:value-of select="."/>
                <xsl:text>", </xsl:text>
            </xsl:for-each>
            <xsl:text></xsl:text>
            <xsl:text>}, </xsl:text>
        </xsl:if>

        <xsl:text>"attributes": [</xsl:text>
        <xsl:apply-templates select="xsd:complexType/xsd:attribute" mode="attribute"/>
        <xsl:text>]</xsl:text>

        <xsl:text>, "elements": [</xsl:text>
        <xsl:apply-templates select="//xsd:element[@name=current()/xsd:complexType/xsd:sequence/xsd:element/@ref]"/>
        <xsl:text>]</xsl:text>

        <xsl:text>}</xsl:text>
        <xsl:if test="position() &lt; last()">
            <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="xsd:attribute" mode="attributaae">
        <xsl:param name="name" select="@name"/>

        <xsl:text>{ "name": "</xsl:text>
        <xsl:value-of select="$name"/>

        <xsl:text>", "type": "</xsl:text>
        <xsl:value-of select="@type"/>

        <xsl:text>", "required": </xsl:text>
        <xsl:choose>
            <xsl:when test="@use='required'">true</xsl:when>
            <xsl:otherwise>false</xsl:otherwise>
        </xsl:choose>
        <xsl:text>", "translatable": </xsl:text>
        <xsl:choose>
            <xsl:when test="count(xsd:annotation/xsd:appInfo/xsd:meta.attribute[@translatable = 'true']) &gt; 0">true</xsl:when>
            <xsl:otherwise>false</xsl:otherwise>
        </xsl:choose>
        <xsl:text>}</xsl:text>
        <xsl:if test="position() &lt; last()">
            <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>
