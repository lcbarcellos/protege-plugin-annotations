/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package br.ufes.inf.nemo.protege.test;

import br.ufes.inf.nemo.protege.annotations.EditorKitMenuAction;
import org.junit.Test;
import static org.junit.Assert.*;

/**
 *
 * @author luciano
 */
@EditorKitMenuAction(
        id = "ufopp.menuitem",
        name = "Do something",
        editorKitId = "OWLEditorKit",
        path = "org.protege.editor.core.application.menu.FileMenu/SlotAA-Z",
        toolTip = "Just that. Do something"
)
public class MenuAction {

    @Test
    public void testSomething() {
        System.out.println("Ok");
    }
}
