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
                xmlns:l="l"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exsl="http://exslt.org/common" extension-element-prefixes="exsl">
    <xsl:output method="text"/>

    <xsl:param name="package-name" select="''"/>

    <xsl:variable name="basedOn">
        <xsl:value-of select="
            /xsd:schema
                /xsd:element[@name='class']
                    /xsd:complexType
                        /xsd:attribute[@name='value']
                            /xsd:annotation
                                /xsd:appInfo
                                    /xsd:meta.attribute/@basedOn"/>
    </xsl:variable>
    <xsl:variable name="simpleBasedOn">
        <xsl:call-template name="simple-name">
            <xsl:with-param name="name" select="$basedOn"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="pluginId">
        <xsl:choose>
            <xsl:when test="$simpleBasedOn = 'EditorKitHook'">
                <xsl:value-of select="$simpleBasedOn"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="
                    /xsd:schema
                        /xsd:annotation
                            /xsd:appInfo
                                /xsd:meta.schema/@id"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:template name="simple-name">
        <xsl:param name="name"/>
        <xsl:variable name="noColon" select="substring-before($name, ':')"/>
        <xsl:variable name="simple" select="substring-after($name, '.')"/>
        <xsl:choose>
            <xsl:when test="$simple = ''">
                <xsl:choose>
                    <xsl:when test="noColon = ''">
                        <xsl:value-of select="$name"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$noColon"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="simple-name">
                    <xsl:with-param name="name" select="$simple"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="/">
        <xsl:call-template name="l">
            <xsl:with-param name="content">
                <l:l>
                    <l:l><xsl:value-of select="concat('package ', $package-name, ';')"/></l:l>
                    <l:l/>
                    <l:l><xsl:value-of select="concat('import ', $package-name, '.source.Attribute;')"/></l:l>
                    <l:l><xsl:value-of select="concat('import ', $package-name, '.source.Element;')"/></l:l>
                    <l:l><xsl:value-of select="concat('import ', $package-name, '.source.ExtensionPoint;')"/></l:l>
                    <l:l>import java.lang.annotation.ElementType;</l:l>
                    <l:l>import java.lang.annotation.Retention;</l:l>
                    <l:l>import java.lang.annotation.RetentionPolicy;</l:l>
                    <l:l>import java.lang.annotation.Target;</l:l>
                    <l:l/><l:l/>

                    <xsl:apply-templates select="xsd:schema/xsd:element[@name='extension']"/>
                </l:l>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="l">
        <xsl:param name="content"/>
        <xsl:apply-templates select="exsl:node-set($content)//l:l|exsl:node-set($content)//text()" mode="l"/>
    </xsl:template>

    <xsl:template match="*" mode="l"/>
    <xsl:template match="l:l[count(node()) = 0]" mode="l">
        <xsl:text>&#10;</xsl:text>
    </xsl:template>
    <xsl:template match="text()" mode="l">
        <xsl:variable name="is-last-node"
            select="count(following-sibling::node())=0"/>
        <xsl:variable name="is-parent-followed-by-s"
            select="name(../following-sibling::node()[1]) = 'l:s'"/>
        <xsl:variable name="is-followed-by-s"
            select="name(following-sibling::node()[1]) = 'l:s'"/>

        <xsl:if test="not(name(..) = 'l:s') and (count(preceding-sibling::node())=0 or not(name(preceding-sibling::node()[1]) = ''))">
            <xsl:for-each select="ancestor-or-self::l:i">
                <xsl:text>    </xsl:text>
            </xsl:for-each>
        </xsl:if>

        <xsl:value-of select="."/>
        <xsl:if test="$is-last-node and not($is-parent-followed-by-s) or not($is-last-node) and not($is-followed-by-s)">
            <xsl:text>&#10;</xsl:text>
        </xsl:if>
    </xsl:template>


    <xsl:template match="xsd:element[@name='extension']">
        <xsl:variable name="template">
            <xsl:apply-templates select="." mode="build-template"/>
        </xsl:variable>
        <l:l>/*</l:l>
        <xsl:apply-templates select="exsl:node-set($template)" mode="dump"/>
        <l:l>*/</l:l>
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
            <xsl:if test="@name='extension'">
                <xsl:attribute name="x-name">
                    <xsl:value-of select="$pluginId"/>
                </xsl:attribute>
                <xsl:attribute name="x-based-on">
                    <xsl:value-of select="translate($basedOn, ':', '')"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:for-each select="xsd:complexType/xsd:attribute">
                <xsl:choose>
                    <xsl:when test="../../@name='extension' and @name='point'">
                        <xsl:attribute name="c-point">
                            <xsl:value-of select="/xsd:schema/xsd:annotation/xsd:appInfo/xsd:meta.schema/@plugin"/>
                            <xsl:text>.</xsl:text>
                            <xsl:value-of select="$pluginId"/>
                        </xsl:attribute>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="{@name}">
                            <xsl:value-of select="@type"/>
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
        <l:l>@ExtensionPoint(</l:l>
        <l:i>
            <l:l>
                <xsl:text>superClass=</xsl:text>
                <xsl:value-of select="@x-based-on"/>
                <xsl:text>.class,</xsl:text>
            </l:l>
            <l:l>xmlStructure={</l:l>
            <l:i>
                <xsl:apply-templates select=".|.//*" mode="annotation-item"/>
            </l:i>
            <l:l>}</l:l>
        </l:i>
        <l:l>)</l:l>
    </xsl:template>

    <xsl:template match="*" mode="annotation-item">
        <xsl:variable name="has-attributes"
            select="count(@*[not(starts-with(name(), 'x-'))]) &gt; 0"/>
        <l:l>
            <xsl:text>@Element(path="</xsl:text>
            <xsl:apply-templates select="ancestor-or-self::*" mode="dump-path"/>
            <xsl:text>"</xsl:text>
            <xsl:if test="(number(@x-min-occurs) = 0) and (count(@value) &gt; 0)">
                <xsl:text>, fieldName="</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text>"</xsl:text>
            </xsl:if>
            <xsl:if test="$has-attributes">
                <xsl:text>, attributes={</xsl:text>
            </xsl:if>
            <l:i>
            <xsl:for-each select="@*[not(starts-with(name(), 'x-'))]">
                <l:l>
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
                    <xsl:if test="position() &lt; last()">
                        <xsl:text>,</xsl:text>
                    </xsl:if>
                </l:l>
            </xsl:for-each>
            </l:i>
            <xsl:if test="count(@*[not(starts-with(name(), 'x-'))]) &gt; 0">
                <xsl:text>}</xsl:text>
            </xsl:if>
            <xsl:text>)</xsl:text>
            <xsl:if test="position() &lt; last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </l:l>
    </xsl:template>

    <xsl:template match="class" mode="fielddef"/>
    <xsl:template match="*" mode="fielddef">
        <l:l>
            <xsl:choose>
                <xsl:when test="string(@value) = 'string'">
                    <xsl:text>String </xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>// Unsupported type </xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:value-of select="name()"/>
            <xsl:text>()</xsl:text>
            <xsl:choose>
                <xsl:when test="name() = 'editorKitId'">
                    <xsl:text> default "OWLEditorKit"</xsl:text>
                </xsl:when>
                <xsl:when test="@x-min-occurs = 0">
                    <xsl:text> default ""</xsl:text>
                </xsl:when>
            </xsl:choose>
            <xsl:text>;</xsl:text>
        </l:l>
    </xsl:template>


    <xsl:template match="extension" mode="typedef">
        <l:l>@Target(ElementType.TYPE)</l:l>
        <l:l>@Retention(RetentionPolicy.SOURCE)</l:l>
        <l:l>
            <xsl:text>public @interface </xsl:text>
            <xsl:value-of select="@x-name"/>
            <xsl:text> {</xsl:text>
        </l:l>
        <l:i>
            <l:l>String id();</l:l>
            <xsl:apply-templates mode="fielddef"/>
        </l:i>
        <l:l>}</l:l>
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
