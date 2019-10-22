/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package br.ufes.inf.nemo.protege.test;

import br.ufes.inf.nemo.protege.annotations.ViewComponent;
import org.protege.editor.owl.ui.view.AbstractOWLViewComponent;

/**
 *
 * @author luciano
 */
@ViewComponent(
        id = "ufopp.view",
        label = "UFO Validation",
        category = "@org.protege.ontologycategory")
public class View extends AbstractOWLViewComponent {

    @Override
    protected void initialiseOWLView() throws Exception {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    @Override
    protected void disposeOWLView() {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }
}
