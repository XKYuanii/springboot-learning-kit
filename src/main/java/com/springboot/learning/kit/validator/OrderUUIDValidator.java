package com.springboot.learning.kit.validator;

import org.springframework.stereotype.Component;

import com.springboot.learning.kit.exception.OrderValidationException;

//  void validate(T object) throws OrderValidationException;
@Component
public class OrderUUIDValidator implements Validator<Long> {
    @Override
    public void validate(Long uuid) throws OrderValidationException {
        if (uuid == null) {
            throw new OrderValidationException("UUID cannot be null");
        }
        if (uuid < 0) {
            throw new OrderValidationException("UUID cannot be negative");
        }
    }

}