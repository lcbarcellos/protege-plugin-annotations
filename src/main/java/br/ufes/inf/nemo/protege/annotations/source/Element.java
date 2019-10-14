/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package br.ufes.inf.nemo.protege.annotations.source;

import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;

/**
 *
 * @author luciano
 */
@Retention(RetentionPolicy.SOURCE)
public @interface Element {
    String path();
    Attribute[] attributes() default {};
    String fieldName() default "";
}
