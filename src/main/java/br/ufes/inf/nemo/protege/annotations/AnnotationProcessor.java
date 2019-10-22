/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package br.ufes.inf.nemo.protege.annotations;

import br.ufes.inf.nemo.protege.annotations.source.Attribute;
import br.ufes.inf.nemo.protege.annotations.source.ExtensionPoint;
import com.google.auto.service.AutoService;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.annotation.processing.AbstractProcessor;
import javax.annotation.processing.Processor;
import javax.annotation.processing.RoundEnvironment;
import javax.annotation.processing.SupportedAnnotationTypes;
import javax.annotation.processing.SupportedOptions;
import javax.annotation.processing.SupportedSourceVersion;
import javax.lang.model.SourceVersion;
import javax.lang.model.element.AnnotationMirror;
import javax.lang.model.element.AnnotationValue;
import javax.lang.model.element.AnnotationValueVisitor;
import javax.lang.model.element.Element;
import javax.lang.model.element.ExecutableElement;
import javax.lang.model.element.TypeElement;
import javax.lang.model.element.VariableElement;
import javax.lang.model.type.TypeMirror;
import static javax.tools.StandardLocation.CLASS_OUTPUT;
import static javax.tools.StandardLocation.SOURCE_PATH;
import javax.xml.transform.Result;
import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.URIResolver;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import org.codehaus.plexus.util.IOUtil;

/**
 *
 * @author luciano
 */
@SupportedAnnotationTypes({
    "br.ufes.inf.nemo.protege.annotations.EditorKitMenuAction",
    "br.ufes.inf.nemo.protege.annotations.ViewComponent"
})
@SupportedSourceVersion(SourceVersion.RELEASE_8)
@SupportedOptions({})
@AutoService(Processor.class)
public class AnnotationProcessor extends AbstractProcessor {

    private List<String> tagStack = new ArrayList<>(10);
    private boolean lastItemIsEmpty = false;
    private PrintWriter out;
    private ByteArrayOutputStream tempPluginXML;
    private boolean closed;

    private void printIndent(int i) {
        for (int k = 0; k <= i; k++) {
            out.print("    ");
        }
    }

    private void closeTags(int i) {
        for (int j = tagStack.size() - 1; j >= i; j--) {
            final String tagName = tagStack.remove(j);
            if (lastItemIsEmpty) {
                out.println("/>");
                lastItemIsEmpty = false;

            } else {
                printIndent(j);
                out.print("</");
                out.print(tagName);
                out.print(">");
                out.println("");

            }
        }
    }

    private void processAnnotation(ExtensionPoint extensionPoint,
            Map<String, String> attributeValues) {

        for (br.ufes.inf.nemo.protege.annotations.source.Element element
                : extensionPoint.xmlStructure()) {

            String fieldName = element.fieldName();
            if (!"".equals(fieldName)) {
                if (!attributeValues.containsKey(fieldName)) {
                    continue;
                }
                if ("".equals(attributeValues.get(fieldName))) {
                    continue;
                }
            }

            String[] path = element.path().split("/");
            int i;
            // Identify path matching
            for (i = 0; i < tagStack.size() && i < path.length; i++) {
                if (!path[i].equals(tagStack.get(i))) {
                    break;
                }
            }
            // Close previous tags
            closeTags(i);
            // Open relevant tags
            for (int j = i; j < path.length; j++) {
                if (lastItemIsEmpty) {
                    out.println(">");
                    lastItemIsEmpty = false;
                }
                tagStack.add(path[j]);
                printIndent(j);
                out.print("<");
                out.print(path[j]);
                if (j < path.length - 1) {
                    out.println(">");
                }
            }
            if (element.attributes().length > 0) {
                for (Attribute attribute : element.attributes()) {
                    out.print(" ");
                    out.print(attribute.name());
                    out.print("=\"");
                    String value = attribute.value();
                    if (value.startsWith("@")) {
                        value = attributeValues.get(value.substring(1));
                        if (value != null) {
                            out.print(value);
                        }
                    } else {
                        out.print(value);
                    }
                    out.print("\"");
                }
            }
            lastItemIsEmpty = true;
        }
        closeTags(0);
    }

    private void processAnnotatedValue(
            Element annotatedElement,
            AnnotationMirror annotationValue,
            ExtensionPoint extensionPointDef,
            RoundEnvironment re) throws IOException {
        final Map<String, String> attributeValues = new HashMap();
        Map<? extends ExecutableElement, ? extends AnnotationValue> values
                = annotationValue.getElementValues();
        ValueConverter converter = new ValueConverter();
        attributeValues.put("class", annotatedElement.asType().toString());
        for (Map.Entry<? extends ExecutableElement, ? extends AnnotationValue> entry : values.entrySet()) {
            ExecutableElement field = entry.getKey();
            AnnotationValue value = entry.getValue();
            attributeValues.put(field.getSimpleName().toString(), value.accept(converter, ""));
        }
        processAnnotation(extensionPointDef, attributeValues);
    }

    private void processAnnotatedElement(
            Element annotatedElement,
            RoundEnvironment re) throws IOException {
        List<? extends AnnotationMirror> annotationMirrors
                = annotatedElement.getAnnotationMirrors();
        printIndent(0);
        out.print("<!-- Element automatically generated for ");
        out.print(annotatedElement.toString());
        out.println(" -->");
        for (AnnotationMirror annotationValue : annotationMirrors) {
            final Element annotationType
                    = annotationValue.getAnnotationType().asElement();
            ExtensionPoint extensionPointDef
                    = annotationType.getAnnotation(ExtensionPoint.class);
            processAnnotatedValue(
                    annotatedElement,
                    annotationValue,
                    extensionPointDef,
                    re);
        }
    }

    @Override
    public boolean process(Set<? extends TypeElement> set, RoundEnvironment re) {
        if (closed) {
            return false;
        }
        try {
            openPluginXMLFile();
            if (!set.isEmpty()) {
                processElements(set, re);
            } else {
                closePluginXMLFile();
                mergePluginFiles();
                closed = true;
            }
            return true;
        } catch (IOException | TransformerException ex) {
            Logger.getLogger(AnnotationProcessor.class.getName()).log(Level.SEVERE, null, ex);
            return false;
        }
    }

    private void processElements(
            Set<? extends TypeElement> set,
            RoundEnvironment re) throws IOException {
        final TypeElement[] annotations = new TypeElement[set.size()];
        final Set<? extends Element> annotatedElements
                = re.getElementsAnnotatedWithAny(set.toArray(annotations));
        for (Element annotatedElement : annotatedElements) {
            processAnnotatedElement(annotatedElement, re);
        }
    }

    private void openPluginXMLFile() {
        if (tempPluginXML == null) {
            tempPluginXML = new ByteArrayOutputStream();
            out = new PrintWriter(tempPluginXML);
            out.println("<?xml version=\"1.0\"?>");
            out.println("<plugin>");
        }
    }

    private void closePluginXMLFile() {
        out.println("</plugin>");
        out.close();
    }

    private void mergePluginFiles() throws IOException, TransformerException {

        ByteArrayOutputStream pluginBuffer = new ByteArrayOutputStream();
        try (
                InputStream pluginStream = processingEnv.getFiler()
                        .getResource(CLASS_OUTPUT, "", "plugin.xml")
                        .openInputStream();
        ) {
            IOUtil.copy(pluginStream, pluginBuffer);
        }

        try (
                InputStream xsltStream = getClass()
                        .getResourceAsStream("merge-plugin-files.xsl");

                InputStream pluginStream =
                        new ByteArrayInputStream(pluginBuffer.toByteArray());

                OutputStream mergedStream = processingEnv.getFiler()
                        .createResource(CLASS_OUTPUT, "", "plugin.xml")
                        .openOutputStream()
        ) {
            Source xslt = new StreamSource(xsltStream);
            Source plugin = new StreamSource(pluginStream);
            Result merged = new StreamResult(mergedStream);

            TransformerFactory factory = TransformerFactory.newInstance();
            Transformer transformer = factory.newTransformer(xslt);
            transformer.setURIResolver(new URIResolver() {
                @Override
                public Source resolve(String string, String string1) throws TransformerException {
                    final byte[] byteArray = tempPluginXML.toByteArray();
                    final ByteArrayInputStream inputStream
                            = new ByteArrayInputStream(byteArray);
                    return new StreamSource(inputStream);
                }
            });
            transformer.transform(plugin, merged);
        }
    }
}

class ValueConverter implements AnnotationValueVisitor<String, String> {

    @Override
    public String visit(AnnotationValue av, String p) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public String visitBoolean(boolean bln, String p) {
        return String.valueOf(bln);
    }

    @Override
    public String visitByte(byte b, String p) {
        return String.valueOf(b);
    }

    @Override
    public String visitChar(char c, String p) {
        return String.valueOf(c);
    }

    @Override
    public String visitDouble(double d, String p) {
        return String.valueOf(d);
    }

    @Override
    public String visitFloat(float f, String p) {
        return String.valueOf(f);
    }

    @Override
    public String visitInt(int i, String p) {
        return String.valueOf(i);
    }

    @Override
    public String visitLong(long l, String p) {
        return String.valueOf(l);
    }

    @Override
    public String visitShort(short s, String p) {
        return String.valueOf(s);
    }

    @Override
    public String visitString(String string, String p) {
        return string;
    }

    @Override
    public String visitType(TypeMirror tm, String p) {
        return tm.toString();
    }

    @Override
    public String visitEnumConstant(VariableElement ve, String p) {
        return ve.toString();
    }

    @Override
    public String visitAnnotation(AnnotationMirror am, String p) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public String visitArray(List<? extends AnnotationValue> list, String p) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public String visitUnknown(AnnotationValue av, String p) {
        throw new UnsupportedOperationException("Not supported yet.");
    }
}
